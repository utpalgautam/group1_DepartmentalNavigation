enum LocationType { building, faculty, lab, hall, department, facility, other }

class LocationModel {
  final String id;
  final String name;
  final LocationType type;
  final String? buildingId;
  final int? floor;
  final String? roomNumber;
  final String? description;
  final List<String> tags;
  final int searchCount;
  final bool isActive;

  LocationModel({
    required this.id,
    required this.name,
    required this.type,
    this.buildingId,
    this.floor,
    this.roomNumber,
    this.description,
    this.tags = const [],
    this.searchCount = 0,
    this.isActive = true,
  });

  factory LocationModel.fromFirestore(Map<String, dynamic> data, String id) {
    return LocationModel(
      id: id,
      name: data['name'] ?? '',
      type: _parseLocationType(data['type']),
      buildingId: data['buildingId'] as String?,
      floor: data['floor'] as int?,
      roomNumber: data['roomNumber'] as String?,
      description: data['description'] as String?,
      tags: List<String>.from(data['tags'] ?? []),
      searchCount: data['searchCount'] ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }

  static LocationType _parseLocationType(String? type) {
    switch (type?.toLowerCase()) {
      case 'building':   return LocationType.building;
      case 'faculty':    return LocationType.faculty;
      case 'lab':        return LocationType.lab;
      case 'hall':       return LocationType.hall;
      case 'department': return LocationType.department;
      case 'facility':   return LocationType.facility;
      default:           return LocationType.other;
    }
  }

  String get typeString {
    switch (type) {
      case LocationType.building:   return 'Building';
      case LocationType.faculty:    return 'Faculty Cabin';
      case LocationType.lab:        return 'Laboratory';
      case LocationType.hall:       return 'Hall';
      case LocationType.department: return 'Department';
      case LocationType.facility:   return 'Facility';
      case LocationType.other:      return 'Other';
    }
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'type': type.toString().split('.').last,
        if (buildingId != null) 'buildingId': buildingId,
        if (floor != null) 'floor': floor,
        if (roomNumber != null) 'roomNumber': roomNumber,
        if (description != null) 'description': description,
        'tags': tags,
        'searchCount': searchCount,
        'isActive': isActive,
      };
}