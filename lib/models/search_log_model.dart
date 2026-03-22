import 'package:cloud_firestore/cloud_firestore.dart';

class SearchLogModel {
  final String buildingId;
  final String buildingName;
  final String platform;
  final String query;
  final DateTime timestamp;

  SearchLogModel({
    required this.buildingId,
    required this.buildingName,
    required this.platform,
    required this.query,
    required this.timestamp,
  });

  Map<String, dynamic> toFirestore() => {
        'buildingId': buildingId,
        'buildingName': buildingName,
        'platform': platform,
        'query': query,
        'timestamp': Timestamp.fromDate(timestamp),
      };
}
