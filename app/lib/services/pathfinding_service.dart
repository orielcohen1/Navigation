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
/// The algorithm works on a unified graph that merges every floor's adjacency
/// list and connects them with inter-floor edges (escalators / elevators).
class PathfindingService {
  final MallData mallData;

  PathfindingService(this.mallData);

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Returns the shortest path from [startNodeId] to [endNodeId], or null if
  /// no path exists.
  NavigationPath? findPath(String startNodeId, String endNodeId) {
    if (startNodeId == endNodeId) {
      final floorId = mallData.floorForNode(startNodeId) ?? '';
      return NavigationPath(
        segments: [PathSegment(nodeId: startNodeId, floorId: floorId)],
        totalDistanceUnits: 0,
      );
    }

    final graph = _buildUnifiedGraph();
    final endNode = _getNode(endNodeId);
    if (endNode == null || !graph.containsKey(startNodeId)) return null;

    final gScore = <String, double>{startNodeId: 0};
    final cameFrom = <String, String>{};
    final visited = <String>{};

    // Min-heap ordered by f = g + h
    final openSet = PriorityQueue<String>(
      (a, b) {
        final fa = (gScore[a] ?? double.infinity) + _heuristic(a, endNode);
        final fb = (gScore[b] ?? double.infinity) + _heuristic(b, endNode);
        return fa.compareTo(fb);
      },
    )..add(startNodeId);

    while (openSet.isNotEmpty) {
      final current = openSet.removeFirst();
      if (visited.contains(current)) continue;
      visited.add(current);

      if (current == endNodeId) {
        return _reconstructPath(cameFrom, endNodeId);
      }

      final neighbors = graph[current] ?? [];
      for (final (neighborId, edgeWeight) in neighbors) {
        if (visited.contains(neighborId)) continue;
        final tentativeG = (gScore[current] ?? double.infinity) + edgeWeight;
        if (tentativeG < (gScore[neighborId] ?? double.infinity)) {
          gScore[neighborId] = tentativeG;
          cameFrom[neighborId] = current;
          openSet.add(neighborId); // lazy: stale entries skipped via visited set
        }
      }
    }

    return null; // no path found
  }

  // ── Graph construction ───────────────────────────────────────────────────────

  /// Builds one adjacency list containing every node from every floor, then
  /// splices in inter-floor edges.
  Map<String, List<(String, double)>> _buildUnifiedGraph() {
    final graph = <String, List<(String, double)>>{};

    for (final floor in mallData.floors.values) {
      final adj = floor.buildAdjacency();
      for (final entry in adj.entries) {
        graph[entry.key] = List.of(entry.value);
      }
    }

    for (final ife in mallData.interFloorEdges) {
      final fromNode = _getNode(ife.fromNodeId);
      final toNode = _getNode(ife.toNodeId);
      if (fromNode == null || toNode == null) continue;

      // Inter-floor transitions are cheap — they represent a fixed physical act
      // (riding an escalator) rather than walking distance.
      const interFloorCost = 50.0;

      graph.putIfAbsent(ife.fromNodeId, () => []).add((ife.toNodeId, interFloorCost));
      graph.putIfAbsent(ife.toNodeId, () => []).add((ife.fromNodeId, interFloorCost));
    }

    return graph;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  MapNode? _getNode(String nodeId) {
    for (final floor in mallData.floors.values) {
      final node = floor.nodes[nodeId];
      if (node != null) return node;
    }
    return null;
  }

  /// Euclidean distance heuristic — admissible for straight-line map layouts.
  double _heuristic(String nodeId, MapNode endNode) {
    final node = _getNode(nodeId);
    return node == null ? double.infinity : node.distanceTo(endNode);
  }

  NavigationPath _reconstructPath(Map<String, String> cameFrom, String endNodeId) {
    final ids = <String>[];
    var current = endNodeId;
    while (cameFrom.containsKey(current)) {
      ids.add(current);
      current = cameFrom[current]!;
    }
    ids.add(current); // start node
    final orderedIds = ids.reversed.toList();

    double total = 0;
    final segments = <PathSegment>[];
    for (int i = 0; i < orderedIds.length; i++) {
      final nodeId = orderedIds[i];
      final floorId = mallData.floorForNode(nodeId) ?? '';
      segments.add(PathSegment(nodeId: nodeId, floorId: floorId));
      if (i > 0) {
        final prev = _getNode(orderedIds[i - 1]);
        final curr = _getNode(nodeId);
        if (prev != null && curr != null) total += prev.distanceTo(curr);
      }
    }

    return NavigationPath(segments: segments, totalDistanceUnits: total);
  }
}
