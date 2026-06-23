import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Drawn on top of the camera preview.
/// [arrowAngleDeg]: 0° = arrow points up (device facing destination),
///                  90° = destination is 90° clockwise from where device faces.
class AROverlayWidget extends StatelessWidget {
  final double arrowAngleDeg;
  final String destinationName;
  final double distanceMeters;

  const AROverlayWidget({
    super.key,
    required this.arrowAngleDeg,
    required this.destinationName,
    required this.distanceMeters,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Directional arrow ──────────────────────────────────────────────
        Center(
          child: Transform.rotate(
            angle: arrowAngleDeg * math.pi / 180,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.navigation, size: 90, color: Colors.blue.shade400),
                const SizedBox(height: 4),
                Container(
                  width: 4,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Destination label + distance ───────────────────────────────────
        Positioned(
          bottom: 60,
          left: 24,
          right: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  destinationName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${distanceMeters.toStringAsFixed(0)} m away',
                  style: TextStyle(color: Colors.grey.shade300, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
