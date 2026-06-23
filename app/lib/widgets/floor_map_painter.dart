import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/floor_map.dart';
import '../models/mall_data.dart';
import '../models/poi.dart';
import '../services/pathfinding_service.dart';

/// [CustomPainter] that draws an entire floor:
///   1. Corridor edges (grey)
///   2. Active route (blue, thick)
///   3. POI markers (orange circles)
///   4. User position (blue pulsing dot)
///   5. Destination marker (red pin)
class FloorMapPainter extends CustomPainter {
  final FloorMap floor;
  final MallData mallData;
  final NavigationPath? path;
  final String? userNodeId;
  final String? destinationNodeId;

  FloorMapPainter({
    required this.floor,
    required this.mallData,
    this.path,
    this.userNodeId,
    this.destinationNodeId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / mallData.mapWidth;
    final sy = size.height / mallData.mapHeight;

    _drawEdges(canvas, sx, sy);
    _drawPath(canvas, sx, sy);
    _drawPOIs(canvas, sx, sy);
    if (destinationNodeId != null) _drawDestination(canvas, sx, sy);
    if (userNodeId != null) _drawUser(canvas, sx, sy);
  }

  void _drawEdges(Canvas canvas, double sx, double sy) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    for (final edge in floor.edges) {
      final from = floor.nodes[edge.fromId];
      final to = floor.nodes[edge.toId];
      if (from == null || to == null) continue;
      canvas.drawLine(
        Offset(from.x * sx, from.y * sy),
        Offset(to.x * sx, to.y * sy),
        paint,
      );
    }
  }

  void _drawPath(Canvas canvas, double sx, double sy) {
    if (path == null) return;

    final nodeIds = path!.segments
        .where((s) => s.floorId == floor.id)
        .map((s) => s.nodeId)
        .toList();

    if (nodeIds.length < 2) return;

    final paint = Paint()
      ..color = Colors.blue.shade600
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < nodeIds.length - 1; i++) {
      final from = floor.nodes[nodeIds[i]];
      final to = floor.nodes[nodeIds[i + 1]];
      if (from == null || to == null) continue;
      canvas.drawLine(
        Offset(from.x * sx, from.y * sy),
        Offset(to.x * sx, to.y * sy),
        paint,
      );

      // Draw a small direction chevron at the midpoint
      _drawChevron(canvas, from, to, sx, sy);
    }
  }

  void _drawChevron(Canvas canvas, dynamic from, dynamic to, double sx, double sy) {
    final midX = (from.x + to.x) / 2 * sx;
    final midY = (from.y + to.y) / 2 * sy;
    final angle = math.atan2(
      (to.y - from.y) * sy,
      (to.x - from.x) * sx,
    );

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.save();
    canvas.translate(midX, midY);
    canvas.rotate(angle);
    final path = Path()
      ..moveTo(-6, -5)
      ..lineTo(0, 0)
      ..lineTo(-6, 5);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawPOIs(Canvas canvas, double sx, double sy) {
    final fill = Paint()..color = Colors.orange.shade400;
    final border = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final poi in mallData.pois.where((p) => p.floorId == floor.id)) {
      final node = floor.nodes[poi.nodeId];
      if (node == null) continue;
      final center = Offset(node.x * sx, node.y * sy);
      canvas.drawCircle(center, 8, fill);
      canvas.drawCircle(center, 8, border);
    }
  }

  void _drawUser(Canvas canvas, double sx, double sy) {
    final node = floor.nodes[userNodeId!];
    if (node == null) return;
    final center = Offset(node.x * sx, node.y * sy);

    // Outer pulse ring
    canvas.drawCircle(
      center, 18,
      Paint()..color = Colors.blue.withOpacity(0.25),
    );
    // Inner solid dot
    canvas.drawCircle(center, 10, Paint()..color = Colors.blue.shade700);
    canvas.drawCircle(
      center, 10,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawDestination(Canvas canvas, double sx, double sy) {
    final node = floor.nodes[destinationNodeId!];
    if (node == null) return;
    final center = Offset(node.x * sx, node.y * sy);

    canvas.drawCircle(center, 14, Paint()..color = Colors.red.shade600);
    canvas.drawCircle(
      center, 14,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(FloorMapPainter old) =>
      old.path != path ||
      old.userNodeId != userNodeId ||
      old.destinationNodeId != destinationNodeId ||
      old.floor.id != floor.id;
}
