import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:provider/provider.dart';
import '../models/node.dart';
import '../models/mall_data.dart';
import '../state/app_state.dart';
import '../widgets/ar_overlay_widget.dart';

/// AR navigation screen: camera feed + compass-driven directional arrow.
///
/// Arrow angle = (map bearing to next waypoint) − (device compass heading).
/// When the arrow points up the user is facing their next waypoint.
class ARScreen extends StatefulWidget {
  const ARScreen({super.key});

  @override
  State<ARScreen> createState() => _ARScreenState();
}

class _ARScreenState extends State<ARScreen> {
  CameraController? _cameraController;
  StreamSubscription<CompassEvent>? _compassSub;
  double _heading = 0;
  bool _cameraReady = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initCompass();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty || !mounted) return;

    final back = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      back,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (!mounted) return;
    setState(() => _cameraReady = true);
  }

  void _initCompass() {
    _compassSub = FlutterCompass.events?.listen((event) {
      if (event.heading == null || !mounted) return;
      // Only update local state — AppState.updateHeading does not notify listeners
      setState(() => _heading = event.heading!);
      context.read<AppState>().updateHeading(event.heading!);
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _compassSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Camera feed ───────────────────────────────────────────────────
        _cameraReady && _cameraController != null
            ? CameraPreview(_cameraController!)
            : Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),

        // ── AR overlay ────────────────────────────────────────────────────
        if (appState.isNavigating && appState.mallData != null)
          _buildAROverlay(appState)
        else
          _buildIdleOverlay(appState),
      ],
    );
  }

  Widget _buildAROverlay(AppState appState) {
    final mallData = appState.mallData!;
    final nextNodeId = appState.nextWaypointNodeId;

    if (nextNodeId == null || appState.userNodeId == null) {
      return _buildIdleOverlay(appState);
    }

    final userNode = _findNode(mallData, appState.userNodeId!);
    final nextNode = _findNode(mallData, nextNodeId);
    if (userNode == null || nextNode == null) return _buildIdleOverlay(appState);

    // Bearing from user to next waypoint (0° = map-north/up, clockwise)
    final bearing = userNode.bearingTo(nextNode);

    // Rotate so the arrow points up when device faces the waypoint
    final arrowAngle = (bearing - _heading + 360) % 360;

    final distMeters = appState.path!.totalDistanceUnits * mallData.metersPerUnit;

    return AROverlayWidget(
      arrowAngleDeg: arrowAngle,
      destinationName: appState.destination!.name,
      distanceMeters: distMeters,
    );
  }

  Widget _buildIdleOverlay(AppState appState) {
    final String message;
    final Color bgColor;

    if (appState.hasArrived) {
      message = 'You\'ve arrived at ${appState.destination!.name}!';
      bgColor = Colors.green.shade800.withOpacity(0.85);
    } else if (!appState.hasLocation) {
      message = 'Scan a QR code first';
      bgColor = Colors.black54;
    } else if (!appState.hasDestination) {
      message = 'Select a destination from Search';
      bgColor = Colors.black54;
    } else {
      message = 'Route ready — check Map view';
      bgColor = Colors.black54;
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 17),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Searches all floors for the node id and returns the [MapNode].
  MapNode? _findNode(MallData mallData, String nodeId) {
    for (final floor in mallData.floors.values) {
      final node = floor.nodes[nodeId];
      if (node != null) return node;
    }
    return null;
  }
}
