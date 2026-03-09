import 'package:cloud_firestore/cloud_firestore.dart';

enum UserType { student, faculty, staff, admin}

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? branch;
  final String? year;
  final UserType userType;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final String? profileImageUrl;
  final List<String> savedLocations;
  final List<String> recentSearches;
  final Map<String, dynamic> preferences;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.branch,
    this.year,
    required this.userType,
    required this.createdAt,
    this.lastLogin,
    this.profileImageUrl,
    this.savedLocations = const [],
    this.recentSearches = const [],
    this.preferences = const {},
  });

  // Convert from Firestore document
  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      branch: data['branch'],
      year: data['year'],
      userType: _parseUserType(data['userType']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
      profileImageUrl: data['profileImageUrl'],
      savedLocations: List<String>.from(data['savedLocations'] ?? []),
      recentSearches: List<String>.from(data['recentSearches'] ?? []),
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'branch': branch,
      'year': year,
      'userType': userType.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'profileImageUrl': profileImageUrl,
      'savedLocations': savedLocations,
      'recentSearches': recentSearches,
      'preferences': preferences,
    };
  }

  static UserType _parseUserType(String? type) {
    switch (type?.toLowerCase()) {
      case 'student':
        return UserType.student;
      case 'faculty':
        return UserType.faculty;
      case 'staff':
        return UserType.staff;
      case 'admin':
        return UserType.admin;
      default:
        return UserType.student;
    }
  }

  String get userTypeString {
    switch (userType) {
      case UserType.student:
        return 'Student';
      case UserType.faculty:
        return 'Faculty';
      case UserType.staff:
        return 'Staff';
      case UserType.admin:
        return 'Admin';
    }
  }

  UserModel copyWith({
    String? email,
    String? name,
    String? branch,
    String? year,
    UserType? userType,
    DateTime? lastLogin,
    String? profileImageUrl,
    List<String>? savedLocations,
    List<String>? recentSearches,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      name: name ?? this.name,
      branch: branch ?? this.branch,
      year: year ?? this.year,
      userType: userType ?? this.userType,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      savedLocations: savedLocations ?? this.savedLocations,
      recentSearches: recentSearches ?? this.recentSearches,
      preferences: preferences ?? this.preferences,
    );
  }
}