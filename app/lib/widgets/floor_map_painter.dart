import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/floor_map.dart';
import '../models/mall_data.dart';
import '../models/node.dart';
import '../services/pathfinding_service.dart';

/// [CustomPainter] that draws an entire floor:
///   1. Corridor edges (grey)
///   2. Active route (blue, thick)
///   3. POI markers (orange circles)
///   4. Destination marker (red pin)
///   5. User heading cone (compass-driven, gradient blue arc)
///   6. User position dot (blue, on top of cone)
///   7. Node labels for named landmarks
class FloorMapPainter extends CustomPainter {
  final FloorMap floor;
  final MallData mallData;
  final NavigationPath? path;
  final String? userNodeId;
  final String? destinationNodeId;
  final double? userHeading; // null = compass unavailable, no cone drawn

  FloorMapPainter({
    required this.floor,
    required this.mallData,
    this.path,
    this.userNodeId,
    this.destinationNodeId,
    this.userHeading,
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
    _drawNodeLabels(canvas, sx, sy);
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

    final paint = Paint()
      ..color = Colors.blue.shade600
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    final segments = path!.segments;
    for (int i = 0; i < segments.length - 1; i++) {
      final seg = segments[i];
      final next = segments[i + 1];
      // Only draw when both consecutive nodes are on this floor
      if (seg.floorId != floor.id || next.floorId != floor.id) continue;
      final from = floor.nodes[seg.nodeId];
      final to = floor.nodes[next.nodeId];
      if (from == null || to == null) continue;
      canvas.drawLine(
        Offset(from.x * sx, from.y * sy),
        Offset(to.x * sx, to.y * sy),
        paint,
      );
      _drawChevron(canvas, from, to, sx, sy);
    }
  }

  void _drawChevron(Canvas canvas, MapNode from, MapNode to, double sx, double sy) {
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
    final chevron = Path()
      ..moveTo(-6, -5)
      ..lineTo(0, 0)
      ..lineTo(-6, 5);
    canvas.drawPath(chevron, paint);
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

    // Draw heading cone behind the dot when compass is available
    if (userHeading != null) {
      _drawHeadingCone(canvas, center, userHeading!);
    }

    // Outer pulse ring
    canvas.drawCircle(
      center, 18,
      Paint()..color = Colors.blue.withOpacity(0.25),
    );
    // Inner solid dot (drawn last so it sits on top of the cone)
    canvas.drawCircle(center, 10, Paint()..color = Colors.blue.shade700);
    canvas.drawCircle(
      center, 10,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
  }

  /// Draws a gradient cone in the direction the user is facing.
  ///
  /// [headingDeg]: compass bearing, 0 = north (map-up), clockwise.
  /// The cone fades from opaque at the dot to transparent at the tip.
  void _drawHeadingCone(Canvas canvas, Offset center, double headingDeg) {
    const coneLength = 42.0; // screen pixels (scales with InteractiveViewer zoom)
    const halfAngleRad = 32.0 * math.pi / 180; // 64° total cone width

    // Convert compass heading to canvas angle.
    // Canvas 0° = right (+x); north (heading 0°) must point up (-y) → subtract π/2.
    final canvasAngle = headingDeg * math.pi / 180 - math.pi / 2;

    final coneRect = Rect.fromCircle(center: center, radius: coneLength);

    // Radial gradient: solid at centre, transparent at the tip
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.blue.shade600.withOpacity(0.55),
          Colors.blue.shade400.withOpacity(0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(coneRect)
      ..style = PaintingStyle.fill;

    final conePath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(
        center.dx + coneLength * math.cos(canvasAngle - halfAngleRad),
        center.dy + coneLength * math.sin(canvasAngle - halfAngleRad),
      )
      ..arcTo(coneRect, canvasAngle - halfAngleRad, 2 * halfAngleRad, false)
      ..close();

    canvas.drawPath(conePath, paint);
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

  void _drawNodeLabels(Canvas canvas, double sx, double sy) {
    for (final node in floor.nodes.values) {
      if (node.label == null) continue;
      final tp = TextPainter(
        text: TextSpan(
          text: node.label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final offset = Offset(node.x * sx - tp.width / 2, node.y * sy + 14);
      tp.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(FloorMapPainter old) =>
      old.path != path ||
      old.userNodeId != userNodeId ||
      old.destinationNodeId != destinationNodeId ||
      old.floor.id != floor.id ||
      old.mallData.id != mallData.id ||
      old.userHeading != userHeading;
}
