import 'floor_map.dart';
import 'poi.dart';

/// Connects a node on one floor to a node on another (escalator / elevator / stairs).
class InterFloorEdge {
  final String fromNodeId;
  final String toNodeId;
  final String type; // "escalator" | "elevator" | "stairs"

  const InterFloorEdge({
    required this.fromNodeId,
    required this.toNodeId,
    required this.type,
  });

  factory InterFloorEdge.fromJson(Map<String, dynamic> json) => InterFloorEdge(
        fromNodeId: json['fromNodeId'] as String,
        toNodeId: json['toNodeId'] as String,
        type: json['type'] as String,
      );
}

/// The complete data model for one mall venue.
/// Loaded from a local JSON asset; swap [DataService.loadMallData] to use an API.
class MallData {
  final String id;
  final String name;
  final double mapWidth;         // map coordinate space width  (e.g. 1000)
  final double mapHeight;        // map coordinate space height (e.g. 620)
  final double metersPerUnit;    // real-world scale for distance display
  final Map<String, FloorMap> floors;
  final List<InterFloorEdge> interFloorEdges;
  final List<POI> pois;

  const MallData({
    required this.id,
    required this.name,
    required this.mapWidth,
    required this.mapHeight,
    required this.metersPerUnit,
    required this.floors,
    required this.interFloorEdges,
    required this.pois,
  });

  factory MallData.fromJson(Map<String, dynamic> json) {
    final floors = <String, FloorMap>{};
    for (final f in json['floors'] as List) {
      final floor = FloorMap.fromJson(f as Map<String, dynamic>);
      floors[floor.id] = floor;
    }

    return MallData(
      id: json['id'] as String,
      name: json['name'] as String,
      mapWidth: (json['mapWidth'] as num).toDouble(),
      mapHeight: (json['mapHeight'] as num).toDouble(),
      metersPerUnit: (json['metersPerUnit'] as num?)?.toDouble() ?? 0.1,
      floors: floors,
      interFloorEdges: (json['interFloorEdges'] as List)
          .map((e) => InterFloorEdge.fromJson(e as Map<String, dynamic>))
          .toList(),
      pois: (json['pois'] as List)
          .map((p) => POI.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Returns the floor id and node id that the given QR code maps to.
  /// Returns null if the QR id is not recognised.
  (String floorId, String nodeId)? resolveQR(String qrId) {
    for (final floor in floors.values) {
      final qr = floor.qrCodes[qrId];
      if (qr != null) return (floor.id, qr.nodeId);
    }
    return null;
  }

  /// Finds which floor contains the given node id.
  String? floorForNode(String nodeId) {
    for (final floor in floors.values) {
      if (floor.nodes.containsKey(nodeId)) return floor.id;
    }
    return null;
  }

  List<POI> searchPOIs(String query) =>
      query.isEmpty ? pois : pois.where((p) => p.matchesQuery(query)).toList();
}
