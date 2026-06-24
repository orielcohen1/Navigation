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

  /// Unified adjacency list: nodeId → list of (neighborId, edgeCost).
  late final Map<String, List<_Edge>> _graph;

  /// Set of "fromId|toId" strings for every inter-floor edge (both directions).
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
    _allNodes = nodes;
    _nodeToFloor = nodeToFloor;

    // ── Unified graph ──────────────────────────────────────────────────────────
    final graph = <String, List<_Edge>>{};

    for (final floor in mallData.floors.values) {
      for (final entry in floor.buildAdjacency().entries) {
        graph[entry.key] = [
          for (final neighbor in entry.value)
            _Edge(neighbor.$1, neighbor.$2),
        ];
      }
    }

    for (final ife in mallData.interFloorEdges) {
      if (!nodes.containsKey(ife.fromNodeId) || !nodes.containsKey(ife.toNodeId)) {
        continue;
      }
      graph.putIfAbsent(ife.fromNodeId, () => []).add(_Edge(ife.toNodeId, _interFloorCost));
      graph.putIfAbsent(ife.toNodeId, () => []).add(_Edge(ife.fromNodeId, _interFloorCost));
    }
    _graph = graph;

    // ── Inter-floor pair set ───────────────────────────────────────────────────
    final pairs = <String>{};
    for (final e in mallData.interFloorEdges) {
      pairs.add('${e.fromNodeId}|${e.toNodeId}');
      pairs.add('${e.toNodeId}|${e.fromNodeId}');
    }
    _interFloorPairs = pairs;
  }

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Returns the shortest path from [startNodeId] to [endNodeId], or null when
  /// either node is unknown or the graph is disconnected.
  NavigationPath? findPath(String startNodeId, String endNodeId) {
    if (startNodeId == endNodeId) {
      return NavigationPath(
        segments: [
          PathSegment(
            nodeId: startNodeId,
            floorId: _nodeToFloor[startNodeId] ?? '',
          ),
        ],
        totalDistanceUnits: 0,
      );
    }

    final endNode = _allNodes[endNodeId];
    if (endNode == null || !_graph.containsKey(startNodeId)) return null;

    final endFloorId = _nodeToFloor[endNodeId] ?? '';

    final gScore = <String, double>{startNodeId: 0.0};
    final cameFrom = <String, String>{};
    final visited = <String>{};

    // Store (fScore, nodeId) so priority is fixed at insertion — avoids the
    // bug where a mutable gScore inside the comparator corrupts heap ordering.
    final openSet = PriorityQueue<_QEntry>(
      (a, b) => a.fScore.compareTo(b.fScore),
    );
    openSet.add(_QEntry(_heuristic(startNodeId, endNode, endFloorId), startNodeId));

    while (openSet.isNotEmpty) {
      final current = openSet.removeFirst().nodeId;

      if (visited.contains(current)) continue; // stale entry — skip
      visited.add(current);

      if (current == endNodeId) {
        return _reconstructPath(cameFrom, endNodeId);
      }

      final neighbors = _graph[current];
      if (neighbors == null) continue;

      for (final edge in neighbors) {
        if (visited.contains(edge.toId)) continue;

        final tentativeG = gScore[current]! + edge.cost;
        final prevG = gScore[edge.toId] ?? double.infinity;
        if (tentativeG < prevG) {
          gScore[edge.toId] = tentativeG;
          cameFrom[edge.toId] = current;
          final f = tentativeG + _heuristic(edge.toId, endNode, endFloorId);
          openSet.add(_QEntry(f, edge.toId));
        }
      }
    }

    return null; // no path exists
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Admissible heuristic: Euclidean distance to goal + one inter-floor cost
  /// when [nodeId] is on a different floor than the destination.
  double _heuristic(String nodeId, MapNode endNode, String endFloorId) {
    final node = _allNodes[nodeId];
    if (node == null) return double.infinity;
    double h = node.distanceTo(endNode);
    if (_nodeToFloor[nodeId] != endFloorId) h += _interFloorCost;
    return h;
  }

  NavigationPath _reconstructPath(
    Map<String, String> cameFrom,
    String endNodeId,
  ) {
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
          // Use fixed cost for inter-floor transitions — Euclidean is 0
          // when the two nodes share 2D coordinates (e.g. same escalator point).
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

// ── Private helpers ────────────────────────────────────────────────────────────

class _Edge {
  final String toId;
  final double cost;
  const _Edge(this.toId, this.cost);
}

class _QEntry {
  final double fScore;
  final String nodeId;
  const _QEntry(this.fScore, this.nodeId);
}
