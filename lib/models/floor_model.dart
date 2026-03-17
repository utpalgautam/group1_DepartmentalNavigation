class POI {
  final String name;
  final double x;
  final double y;

  POI({
    required this.name,
    required this.x,
    required this.y,
  });

  factory POI.fromFirestore(Map<String, dynamic> data) {
    return POI(
      name: data['name'] ?? '',
      x: (data['x'] ?? 0.0).toDouble(),
      y: (data['y'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'x': x,
      'y': y,
    };
  }
}

class FloorModel {
  final String buildingId;
  final int floorNumber;

  /// Raw SVG content stored inline (e.g. fetched from Firestore or bundled asset).
  final String? svgMapData;

  /// Remote URL (Firebase Storage or CDN) pointing to the floor plan SVG file.
  final String? svgMapUrl;

  /// Raster fallback: URL of a PNG/JPG floor map image.
  final String? mapImageUrl;

  final List<POI> pois;

  FloorModel({
    required this.buildingId,
    required this.floorNumber,
    this.svgMapData,
    this.svgMapUrl,
    this.mapImageUrl,
    this.pois = const [],
  });

  factory FloorModel.fromFirestore(
      Map<String, dynamic> data, String buildingId, int floorNumber) {
    return FloorModel(
      buildingId: buildingId,
      floorNumber: floorNumber,
      svgMapData: data['svgContent'] as String? ?? data['svgMapData'] as String?,
      svgMapUrl: data['svgMapUrl'] as String?,
      mapImageUrl: data['mapImageUrl'] as String?,
      pois: (data['pois'] as List<dynamic>? ?? [])
          .map((p) => POI.fromFirestore(p as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (svgMapData != null) 'svgMapData': svgMapData,
      if (svgMapUrl != null) 'svgMapUrl': svgMapUrl,
      if (mapImageUrl != null) 'mapImageUrl': mapImageUrl,
      'pois': pois.map((p) => p.toFirestore()).toList(),
    };
  }
}