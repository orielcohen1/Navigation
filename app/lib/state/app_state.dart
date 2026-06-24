import 'package:flutter/foundation.dart';
import '../models/mall_data.dart';
import '../models/poi.dart';
import '../services/data_service.dart';
import '../services/pathfinding_service.dart';

/// Central application state, consumed via [Provider] / [Consumer].
///
/// All navigation logic flows through here:
///   QR scan → position update → A* recalculation → UI rebuild
class AppState extends ChangeNotifier {
  final DataService _dataService;

  AppState(this._dataService);

  // ── State ─────────────────────────────────────────────────────────────────

  MallData? _mallData;

  /// Cached for the lifetime of the session — graph built once on data load.
  PathfindingService? _pathfinder;

  bool _loading = false;
  String? _error;

  String _currentFloorId = 'G';
  String? _userNodeId;       // null until the first QR code is scanned
  POI? _destination;
  NavigationPath? _path;
  double _deviceHeading = 0; // compass degrees, 0 = north, clockwise

  // ── Getters ───────────────────────────────────────────────────────────────

  MallData? get mallData => _mallData;
  bool get loading => _loading;
  String? get error => _error;

  String get currentFloorId => _currentFloorId;
  String? get userNodeId => _userNodeId;
  POI? get destination => _destination;
  NavigationPath? get path => _path;
  double get deviceHeading => _deviceHeading;

  bool get hasLocation => _userNodeId != null;
  bool get hasDestination => _destination != null;

  /// Human-readable name for the user's current node, or null if unknown.
  String? get currentLocationName {
    if (_userNodeId == null || _mallData == null) return null;
    for (final floor in _mallData!.floors.values) {
      final node = floor.nodes[_userNodeId];
      if (node != null) return node.label ?? _userNodeId;
    }
    return _userNodeId;
  }
  bool get hasArrived =>
      _userNodeId != null &&
      _destination != null &&
      _userNodeId == _destination!.nodeId;
  bool get isNavigating => _path != null && !_path!.isEmpty && !hasArrived;

  /// The next node the user should walk toward, used for the AR arrow.
  String? get nextWaypointNodeId {
    if (_path == null || _userNodeId == null) return null;
    final segs = _path!.segments;
    final idx = segs.indexWhere((s) => s.nodeId == _userNodeId);
    if (idx == -1 || idx + 1 >= segs.length) return null;
    return segs[idx + 1].nodeId;
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> loadMallData() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _mallData = await _dataService.loadMallData();
      // Build graph once — reused for every subsequent findPath call
      _pathfinder = PathfindingService(_mallData!);
      _currentFloorId = _mallData!.floors.keys.first;
    } catch (e) {
      _error = 'Failed to load mall data: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Called when a QR code is scanned. Updates user position and recalculates route.
  void onQrScanned(String qrId) {
    if (_mallData == null) return;
    final resolved = _mallData!.resolveQR(qrId);
    if (resolved == null) return; // unknown QR — ignore gracefully

    final (floorId, nodeId) = resolved;
    _userNodeId = nodeId;
    _currentFloorId = floorId; // switch map to user's floor so route is visible
    _recalculatePath();
    notifyListeners();
  }

  void setDestination(POI poi) {
    _destination = poi;
    // Stay on user's floor when location is known; only switch to dest floor otherwise
    if (!hasLocation) _currentFloorId = poi.floorId;
    _recalculatePath();
    notifyListeners();
  }

  void clearDestination() {
    _destination = null;
    _path = null;
    notifyListeners();
  }

  void switchFloor(String floorId) {
    _currentFloorId = floorId;
    notifyListeners();
  }

  /// Updated continuously by the compass stream in [ARScreen] and [MapScreen].
  /// Does NOT call notifyListeners — screens read heading from their own local state.
  void updateHeading(double heading) {
    _deviceHeading = heading;
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _recalculatePath() {
    if (_pathfinder == null || _userNodeId == null || _destination == null) {
      _path = null;
      return;
    }
    _path = _pathfinder!.findPath(_userNodeId!, _destination!.nodeId);
  }
}
