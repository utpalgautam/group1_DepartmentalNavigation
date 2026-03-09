class FloorModel {
  final String buildingId;
  final int floorNumber;

  /// Raw SVG content stored inline (e.g. fetched from Firestore or bundled asset).
  final String? svgMapData;

  /// Remote URL (Firebase Storage or CDN) pointing to the floor plan SVG file.
  final String? svgMapUrl;

  /// Raster fallback: URL of a PNG/JPG floor map image.
  final String? mapImageUrl;

  FloorModel({
    required this.buildingId,
    required this.floorNumber,
    this.svgMapData,
    this.svgMapUrl,
    this.mapImageUrl,
  });

  factory FloorModel.fromFirestore(
      Map<String, dynamic> data, String buildingId, int floorNumber) {
    return FloorModel(
      buildingId: buildingId,
      floorNumber: floorNumber,
      svgMapData: data['svgContent'] as String? ?? data['svgMapData'] as String?,
      svgMapUrl: data['svgMapUrl'] as String?,
      mapImageUrl: data['mapImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (svgMapData != null) 'svgMapData': svgMapData,
      if (svgMapUrl != null) 'svgMapUrl': svgMapUrl,
      if (mapImageUrl != null) 'mapImageUrl': mapImageUrl,
    };
  }
}