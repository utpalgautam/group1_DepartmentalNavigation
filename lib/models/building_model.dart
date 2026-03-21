import 'dart:convert';
import 'dart:typed_data';

/// GPS entry point (door/gate) into a building.
class EntryPoint {
  final String id;
  final String label;
  final double latitude;
  final double longitude;

  EntryPoint({
    required this.id,
    required this.label,
    required this.latitude,
    required this.longitude,
  });

  factory EntryPoint.fromJson(Map<String, dynamic> json) => EntryPoint(
        id: json['id'] ?? '',
        label: json['label'] ?? '',
        latitude: (json['latitude'] ?? 0.0).toDouble(),
        longitude: (json['longitude'] ?? 0.0).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'latitude': latitude,
        'longitude': longitude,
      };
}

class BuildingModel {
  final String id;
  final String name;

  /// GPS centre — used to place the map marker and pan the camera.
  final double latitude;
  final double longitude;

  final List<EntryPoint> entryPoints;
  final int totalFloors;

  /// Base64-encoded image stored in Firestore as `imageUrl`.
  final String? imageUrl;

  BuildingModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.entryPoints = const [],
    required this.totalFloors,
    this.imageUrl,
  });

  /// Decodes [imageUrl] (base64) into raw bytes for display with [Image.memory].
  /// Returns null if [imageUrl] is absent or malformed.
  Uint8List? get imageBytes {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    try {
      // Strip optional data-URI prefix: "data:image/jpeg;base64,..."
      final raw =
          imageUrl!.contains(',') ? imageUrl!.split(',').last : imageUrl!;
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  factory BuildingModel.fromFirestore(Map<String, dynamic> data, String id) {
    final entryPointsData = data['entryPoints'];
    List<EntryPoint> entryPoints = [];

    if (entryPointsData is List) {
      entryPoints = entryPointsData
          .map((e) => EntryPoint.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (entryPointsData is Map) {
      entryPoints = entryPointsData.values
          .map((e) => EntryPoint.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return BuildingModel(
      id: id,
      name: data['name'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      entryPoints: entryPoints,
      totalFloors: data['totalFloors'] ?? 1,
      imageUrl: data['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'entryPoints': entryPoints.map((e) => e.toJson()).toList(),
        'totalFloors': totalFloors,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };
}