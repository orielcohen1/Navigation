import 'node.dart';
import 'edge.dart';

/// A QR code placed at a physical location, referencing its node on the floor map.
class QRCodeMarker {
  final String id;
  final String nodeId;
  final String label;

  const QRCodeMarker({
    required this.id,
    required this.nodeId,
    required this.label,
  });

  factory QRCodeMarker.fromJson(Map<String, dynamic> json) => QRCodeMarker(
        id: json['id'] as String,
        nodeId: json['nodeId'] as String,
        label: json['label'] as String,
      );
}

/// One floor of the mall: a graph of [MapNode]s connected by [MapEdge]s.
class FloorMap {
  final String id;
  final String name;
  final Map<String, MapNode> nodes;    // keyed by node id
  final List<MapEdge> edges;
  final Map<String, QRCodeMarker> qrCodes; // keyed by QR id

  const FloorMap({
    required this.id,
    required this.name,
    required this.nodes,
    required this.edges,
    required this.qrCodes,
  });

  factory FloorMap.fromJson(Map<String, dynamic> json) {
    final nodes = <String, MapNode>{};
    for (final n in json['nodes'] as List) {
      final node = MapNode.fromJson(n as Map<String, dynamic>);
      nodes[node.id] = node;
    }

    final edges = (json['edges'] as List)
        .map((e) => MapEdge.fromJson(e as Map<String, dynamic>))
        .toList();

    final qrCodes = <String, QRCodeMarker>{};
    for (final q in json['qrCodes'] as List) {
      final qr = QRCodeMarker.fromJson(q as Map<String, dynamic>);
      qrCodes[qr.id] = qr;
    }

    return FloorMap(
      id: json['id'] as String,
      name: json['name'] as String,
      nodes: nodes,
      edges: edges,
      qrCodes: qrCodes,
    );
  }

  /// Builds an adjacency list where edge weight = Euclidean distance between nodes,
  /// unless the edge data overrides weight explicitly.
  Map<String, List<(String, double)>> buildAdjacency() {
    final adj = <String, List<(String, double)>>{
      for (final id in nodes.keys) id: [],
    };

    for (final edge in edges) {
      final from = nodes[edge.fromId];
      final to = nodes[edge.toId];
      if (from == null || to == null) continue;

      // Use explicit weight only when it differs from the default 1.0
      final w = edge.weight != 1.0 ? edge.weight : from.distanceTo(to);
      adj[edge.fromId]!.add((edge.toId, w));
      adj[edge.toId]!.add((edge.fromId, w));
    }

    return adj;
  }
}
