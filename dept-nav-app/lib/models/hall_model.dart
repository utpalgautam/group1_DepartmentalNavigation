enum HallType { lectureHall, seminarHall, auditorium, conferenceRoom }

/// Hall model. Physical location details (building, floor, room) are
/// stored in the linked [LocationModel] document (via [locationId]).
class HallModel {
  final String id;
  final String name;
  final HallType type;

  /// ID of the corresponding document in the `locations` collection.
  final String locationId;

  final int capacity;
  final String? contactPerson;

  HallModel({
    required this.id,
    required this.name,
    required this.type,
    required this.locationId,
    required this.capacity,
    this.contactPerson,
  });

  factory HallModel.fromFirestore(Map<String, dynamic> data, String id) =>
      HallModel(
        id: id,
        name: data['name'] ?? '',
        type: _parseHallType(data['type']),
        locationId: data['locationId'] ?? '',
        capacity: data['capacity'] ?? 0,
        contactPerson: data['contactPerson'] as String?,
      );

  static HallType _parseHallType(String? type) {
    switch (type?.toLowerCase()) {
      case 'seminarhall':    return HallType.seminarHall;
      case 'auditorium':     return HallType.auditorium;
      case 'conferenceroom': return HallType.conferenceRoom;
      default:               return HallType.lectureHall;
    }
  }

  String get typeString {
    switch (type) {
      case HallType.lectureHall:    return 'Lecture Hall';
      case HallType.seminarHall:    return 'Seminar Hall';
      case HallType.auditorium:     return 'Auditorium';
      case HallType.conferenceRoom: return 'Conference Room';
    }
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'type': type.toString().split('.').last,
        'locationId': locationId,
        'capacity': capacity,
        if (contactPerson != null) 'contactPerson': contactPerson,
      };
}