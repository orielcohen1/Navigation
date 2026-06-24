import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../widgets/floor_map_painter.dart';

/// Interactive floor map with pan and pinch-zoom support.
/// Shows: corridor graph · active route · user position · destination.
/// The user dot shows a directional cone using the device compass.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  StreamSubscription<CompassEvent>? _compassSub;
  double? _heading; // null = compass not available

  @override
  void initState() {
    super.initState();
    _compassSub = FlutterCompass.events?.listen((event) {
      if (event.heading == null || !mounted) return;
      // Only rebuild when heading changes by more than 3° to avoid excessive repaints
      if (_heading == null || (event.heading! - _heading!).abs() > 3) {
        setState(() => _heading = event.heading!);
      }
    });
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final mallData = appState.mallData;

    if (mallData == null) {
      return const Center(child: Text('Loading map…'));
    }

    final floor = mallData.floors[appState.currentFloorId];
    if (floor == null) {
      return const Center(child: Text('Floor not found.'));
    }

    return Column(
      children: [
        // ── Floor selector tabs ────────────────────────────────────────────
        if (mallData.floors.length > 1)
          _FloorTabBar(
            floors: mallData.floors.keys.toList(),
            currentFloor: appState.currentFloorId,
            onSelect: appState.switchFloor,
            floorNames: {
              for (final f in mallData.floors.values) f.id: f.name,
            },
          ),

        // ── Map canvas ────────────────────────────────────────────────────
        Expanded(
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4.0,
            boundaryMargin: const EdgeInsets.all(80),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AspectRatio(
                aspectRatio: mallData.mapWidth / mallData.mapHeight,
                child: CustomPaint(
                  painter: FloorMapPainter(
                    floor: floor,
                    mallData: mallData,
                    path: appState.path,
                    userNodeId: appState.userNodeId,
                    destinationNodeId: appState.destination?.nodeId,
                    userHeading: _heading,
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Navigation status bar ─────────────────────────────────────────
        _NavStatusBar(appState: appState, metersPerUnit: mallData.metersPerUnit),
      ],
    );
  }
}

class _FloorTabBar extends StatelessWidget {
  final List<String> floors;
  final String currentFloor;
  final ValueChanged<String> onSelect;
  final Map<String, String> floorNames;

  const _FloorTabBar({
    required this.floors,
    required this.currentFloor,
    required this.onSelect,
    required this.floorNames,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Row(
        children: floors.map((id) {
          final selected = id == currentFloor;
          return Expanded(
            child: InkWell(
              onTap: () => onSelect(id),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  floorNames[id] ?? id,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NavStatusBar extends StatelessWidget {
  final AppState appState;
  final double metersPerUnit;

  const _NavStatusBar({required this.appState, required this.metersPerUnit});

  @override
  Widget build(BuildContext context) {
    if (appState.hasArrived) {
      return Container(
        color: Colors.green.shade600,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'You\'ve arrived at ${appState.destination!.name}!',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            TextButton(
              onPressed: appState.clearDestination,
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (!appState.isNavigating) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          appState.hasLocation
              ? 'Select a destination from the Search tab.'
              : 'Scan a QR code to set your location.',
          style: TextStyle(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      );
    }

    final distM = appState.path!.totalDistanceUnits * metersPerUnit;
    final crossFloor = appState.path!.crossesFloors;

    return Container(
      color: Colors.blue.shade600,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.directions_walk, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'To: ${appState.destination!.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '${distM.toStringAsFixed(0)} m${crossFloor ? " · changes floor" : ""}',
                  style: TextStyle(color: Colors.blue.shade100, fontSize: 13),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: appState.clearDestination,
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
