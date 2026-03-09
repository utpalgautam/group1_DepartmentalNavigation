/// A route defined by an ordered list of (x, y) SVG/pixel coordinates
/// that are drawn directly on the floor-plan map.

class RouteModel {
  final String id;

  /// Label or ID of the route's starting location.
  final String fromLocation;

  /// Label or ID of the route's ending location.
  final String toLocation;

  /// Approximate walking distance in metres.
  final double distanceMeters;

  /// Ordered waypoints (SVG coordinates) that define the drawn path.
  final List<RoutePoint> points;

  RouteModel({
    required this.id,
    required this.fromLocation,
    required this.toLocation,
    this.distanceMeters = 0.0,
    required this.points,
  });

  factory RouteModel.fromFirestore(Map<String, dynamic> data, String id) {
    return RouteModel(
      id: id,
      fromLocation: data['fromLocation'] ?? '',
      toLocation: data['toLocation'] ?? '',
      distanceMeters: (data['distanceMeters'] ?? 0.0).toDouble(),
      points: (data['points'] as List<dynamic>?)
              ?.map((p) => RoutePoint.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'fromLocation': fromLocation,
        'toLocation': toLocation,
        'distanceMeters': distanceMeters,
        'points': points.map((p) => p.toJson()).toList(),
      };
}

/// A single (x, y) coordinate on the SVG floor-plan.
class RoutePoint {
  final double x;
  final double y;

  const RoutePoint({required this.x, required this.y});

  factory RoutePoint.fromJson(Map<String, dynamic> json) =>
      RoutePoint(x: (json['x'] ?? 0.0).toDouble(), y: (json['y'] ?? 0.0).toDouble());

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
}
