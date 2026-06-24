import 'package:collection/collection.dart';
import '../models/mall_data.dart';
import '../models/node.dart';

/// One step in a computed route.
class PathSegment {
  final String nodeId;
  final String floorId;
  const PathSegment({required this.nodeId, required this.floorId});
}

/// The result of an A* search: an ordered list of [PathSegment]s and the total
/// distance in map units.
class NavigationPath {
  final List<PathSegment> segments;
  final double totalDistanceUnits;

  const NavigationPath({
    required this.segments,
    required this.totalDistanceUnits,
  });

  bool get isEmpty => segments.isEmpty;
  bool get crossesFloors => segments.map((s) => s.floorId).toSet().length > 1;
}

/// A* pathfinding across all floors of a [MallData] venue.
///
/// All heavy structures (graph, node map, floor lookup) are built once in the
/// constructor and reused across every [findPath] call. Create one instance per
/// venue and keep it alive for the session.
class PathfindingService {
  final MallData mallData;

  // ── Pre-computed structures (built once, O(1) lookup) ────────────────────────

  /// Flat map of every node across all floors — O(1) lookup by id.
  late final Map<String, MapNode> _allNodes;

  /// Reverse lookup: nodeId → floorId — O(1).
  late final Map<String, String> _nodeToFloor;

  /// Unified adjacency list across all floors, including inter-floor edges.
  late final Map<String, List<(String, double)>> _graph;

  /// Set of "fromId|toId" strings for every inter-floor edge (both directions).
  /// Used in O(1) distance reconstruction to correctly account for escalator cost.
  late final Set<String> _interFloorPairs;

  static const double _interFloorCost = 50.0;

  PathfindingService(this.mallData) {
    _buildStructures();
  }

  void _buildStructures() {
    // ── Node map and floor lookup ──────────────────────────────────────────────
    final nodes = <String, MapNode>{};
    final nodeToFloor = <String, String>{};

    for (final floor in mallData.floors.values) {
      for (final node in floor.nodes.values) {
        nodes[node.id] = node;
        nodeToFloor[node.id] = floor.id;
      }
    }
    _allNodes = Map.unmodifiable(nodes);
    _nodeToFloor = Map.unmodifiable(nodeToFloor);

    // ── Unified graph ──────────────────────────────────────────────────────────
    final graph = <String, List<(String, double)>>{};
    for (final floor in mallData.floors.values) {
      for (final entry in floor.buildAdjacency().entries) {
        graph[entry.key] = List.of(entry.value);
      }
    }
    for (final ife in mallData.interFloorEdges) {
      if (!_allNodes.containsKey(ife.fromNodeId) || !_allNodes.containsKey(ife.toNodeId)) {
        continue;
      }
      graph.putIfAbsent(ife.fromNodeId, () => []).add((ife.toNodeId, _interFloorCost));
      graph.putIfAbsent(ife.toNodeId, () => []).add((ife.fromNodeId, _interFloorCost));
    }
    _graph = Map.unmodifiable(graph);

    // ── Inter-floor pair set ───────────────────────────────────────────────────
    _interFloorPairs = {
      for (final e in mallData.interFloorEdges) ...[
        '${e.fromNodeId}|${e.toNodeId}',
        '${e.toNodeId}|${e.fromNodeId}',
      ],
    };
  }

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Returns the shortest path from [startNodeId] to [endNodeId], or null when
  /// either node is unknown or the graph is disconnected.
  NavigationPath? findPath(String startNodeId, String endNodeId) {
    if (startNodeId == endNodeId) {
      return NavigationPath(
        segments: [PathSegment(nodeId: startNodeId, floorId: _nodeToFloor[startNodeId] ?? '')],
        totalDistanceUnits: 0,
      );
    }

    final endNode = _allNodes[endNodeId];
    if (endNode == null || !_graph.containsKey(startNodeId)) return null;

    final endFloorId = _nodeToFloor[endNodeId] ?? '';

    // g[node] = best known cost from start to node
    final gScore = <String, double>{startNodeId: 0.0};
    final cameFrom = <String, String>{};
    final visited = <String>{};

    // Store (fScore, nodeId) so the priority is fixed at insertion time —
    // avoids the bug where a mutable gScore inside the comparator corrupts
    // heap ordering when gScores are updated later.
    final openSet = PriorityQueue<(double, String)>(
      (a, b) => a.$1.compareTo(b.$1),
    );
    openSet.add((_heuristic(startNodeId, endNode, endFloorId), startNodeId));

    while (openSet.isNotEmpty) {
      final (_, current) = openSet.removeFirst();

      if (visited.contains(current)) continue; // stale entry — skip
      visited.add(current);

      if (current == endNodeId) {
        return _reconstructPath(cameFrom, endNodeId);
      }

      for (final (neighborId, edgeWeight) in _graph[current] ?? const []) {
        if (visited.contains(neighborId)) continue;

        final tentativeG = gScore[current]! + edgeWeight;
        if (tentativeG < (gScore[neighborId] ?? double.infinity)) {
          gScore[neighborId] = tentativeG;
          cameFrom[neighborId] = current;
          // Insert new entry with updated fScore; stale entry handled by visited set
          final f = tentativeG + _heuristic(neighborId, endNode, endFloorId);
          openSet.add((f, neighborId));
        }
      }
    }

    return null; // no path exists
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Admissible heuristic: Euclidean distance to goal + one inter-floor cost
  /// when [nodeId] is on a different floor than the destination.
  ///
  /// Adding the inter-floor cost is admissible because any cross-floor path
  /// must traverse at least one inter-floor edge of exactly [_interFloorCost].
  /// This guides A* toward the escalator/elevator rather than exploring the
  /// wrong floor exhaustively.
  double _heuristic(String nodeId, MapNode endNode, String endFloorId) {
    final node = _allNodes[nodeId];
    if (node == null) return double.infinity;
    double h = node.distanceTo(endNode);
    if (_nodeToFloor[nodeId] != endFloorId) h += _interFloorCost;
    return h;
  }

  NavigationPath _reconstructPath(Map<String, String> cameFrom, String endNodeId) {
    // Walk back from end to start
    final ids = <String>[];
    var current = endNodeId;
    while (cameFrom.containsKey(current)) {
      ids.add(current);
      current = cameFrom[current]!;
    }
    ids.add(current); // start node
    final orderedIds = ids.reversed.toList();

    double total = 0.0;
    final segments = <PathSegment>[];

    for (int i = 0; i < orderedIds.length; i++) {
      final nodeId = orderedIds[i];
      segments.add(PathSegment(
        nodeId: nodeId,
        floorId: _nodeToFloor[nodeId] ?? '',
      ));

      if (i > 0) {
        final prevId = orderedIds[i - 1];
        if (_interFloorPairs.contains('$prevId|$nodeId')) {
          // Inter-floor transition: use fixed cost, not Euclidean
          // (the two nodes may share 2D coordinates making Euclidean = 0)
          total += _interFloorCost;
        } else {
          final prev = _allNodes[prevId];
          final curr = _allNodes[nodeId];
          if (prev != null && curr != null) total += prev.distanceTo(curr);
        }
      }
    }

    return NavigationPath(segments: segments, totalDistanceUnits: total);
  }
}
