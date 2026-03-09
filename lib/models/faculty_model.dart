import 'dart:convert';
import 'dart:typed_data';

/// Faculty member. Physical location details are stored in the
/// linked [LocationModel] document (via [locationId]).
class FacultyModel {
  final String id;
  final String name;
  final String designation;

  /// Role e.g. "Professor", "Assistant Professor" – stored as `role` in Firestore.
  final String role;
  final String department;
  final String email;

  /// ID of the corresponding document in the `locations` collection.
  final String locationId;

  /// Legacy HTTP photo URL (may be null).
  final String? photoUrl;

  /// Base64-encoded image stored directly in Firestore as `imageUrl`.
  final String? imageUrl;

  final List<String> researchAreas;

  FacultyModel({
    required this.id,
    required this.name,
    required this.designation,
    this.role = '',
    required this.department,
    required this.email,
    required this.locationId,
    this.photoUrl,
    this.imageUrl,
    this.researchAreas = const [],
  });

  /// Decodes [imageUrl] (base64) into raw bytes for display with [Image.memory].
  /// Returns null if [imageUrl] is absent or malformed.
  Uint8List? get imageBytes {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    try {
      // Strip optional data-URI prefix: "data:image/jpeg;base64,..."
      final raw = imageUrl!.contains(',') ? imageUrl!.split(',').last : imageUrl!;
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  factory FacultyModel.fromFirestore(Map<String, dynamic> data, String id) =>
      FacultyModel(
        id: id,
        name: data['name'] ?? '',
        designation: data['designation'] ?? '',
        role: data['role'] ?? data['designation'] ?? '',
        department: data['department'] ?? '',
        email: data['email'] ?? '',
        locationId: data['locationId'] ?? '',
        photoUrl: data['photoUrl'] as String?,
        imageUrl: data['imageUrl'] as String?,
        researchAreas: List<String>.from(data['researchAreas'] ?? []),
      );

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'designation': designation,
        'role': role,
        'department': department,
        'email': email,
        'locationId': locationId,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'researchAreas': researchAreas,
      };
}