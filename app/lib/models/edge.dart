/// A bidirectional connection between two [MapNode]s on the same floor.
/// Weight defaults to 1.0 and is replaced by Euclidean distance at graph-build time
/// unless explicitly set (e.g. to penalise narrow corridors).
class MapEdge {
  final String fromId;
  final String toId;
  final double weight;

  const MapEdge({
    required this.fromId,
    required this.toId,
    this.weight = 1.0,
  });

  factory MapEdge.fromJson(Map<String, dynamic> json) => MapEdge(
        fromId: json['from'] as String,
        toId: json['to'] as String,
        weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      );
}
