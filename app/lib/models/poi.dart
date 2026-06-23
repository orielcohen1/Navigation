/// A point of interest (store, service, amenity) anchored to a [MapNode].
class POI {
  final String id;
  final String name;
  final String category;
  final String floorId;
  final String nodeId; // the nearest walkable node
  final String icon;   // Material icon name string

  const POI({
    required this.id,
    required this.name,
    required this.category,
    required this.floorId,
    required this.nodeId,
    required this.icon,
  });

  factory POI.fromJson(Map<String, dynamic> json) => POI(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        floorId: json['floorId'] as String,
        nodeId: json['nodeId'] as String,
        icon: json['icon'] as String,
      );

  bool matchesQuery(String query) {
    final q = query.toLowerCase();
    return name.toLowerCase().contains(q) || category.toLowerCase().contains(q);
  }
}
