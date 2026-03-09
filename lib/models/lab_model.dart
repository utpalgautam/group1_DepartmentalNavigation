/// Lab model. Physical location details (building, floor, room number) are
/// stored in the linked [LocationModel] document (via [locationId]).
class LabModel {
  final String id;
  final String name;
  final String department;

  /// ID of the corresponding document in the `locations` collection.
  final String locationId;

  final int capacity;
  final String? incharge;
  final String? inchargeEmail;
  final Map<String, String> timing;

  LabModel({
    required this.id,
    required this.name,
    required this.department,
    required this.locationId,
    required this.capacity,
    this.incharge,
    this.inchargeEmail,
    this.timing = const {},
  });

  factory LabModel.fromFirestore(Map<String, dynamic> data, String id) =>
      LabModel(
        id: id,
        name: data['name'] ?? '',
        department: data['department'] ?? '',
        locationId: data['locationId'] ?? '',
        capacity: data['capacity'] ?? 0,
        incharge: data['incharge'] as String?,
        inchargeEmail: data['inchargeEmail'] as String?,
        timing: Map<String, String>.from(data['timing'] ?? {}),
      );

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'department': department,
        'locationId': locationId,
        'capacity': capacity,
        if (incharge != null) 'incharge': incharge,
        if (inchargeEmail != null) 'inchargeEmail': inchargeEmail,
        'timing': timing,
      };
}