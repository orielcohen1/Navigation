import 'dart:math' as math;

/// A single walkable point on a floor map.
/// Coordinates are in map units (0–1000 × 0–620); scale to screen at render time.
class MapNode {
  final String id;
  final double x;
  final double y;
  final String? label; // shown as tooltip / landmark name if present

  const MapNode({
    required this.id,
    required this.x,
    required this.y,
    this.label,
  });

  factory MapNode.fromJson(Map<String, dynamic> json) => MapNode(
        id: json['id'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        label: json['label'] as String?,
      );

  double distanceTo(MapNode other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Compass bearing (0° = map-north/up, clockwise) from this node to [other].
  /// Map north is assumed to align with real-world north (y decreases = north).
  double bearingTo(MapNode other) {
    final dx = other.x - x;
    final dy = -(other.y - y); // invert y because screen-y increases downward
    final radians = math.atan2(dx, dy);
    return (radians * 180 / math.pi + 360) % 360;
  }
}
