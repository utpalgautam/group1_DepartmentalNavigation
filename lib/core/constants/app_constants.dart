class AppConstants {
  static const String appName = 'NITC Campus Navigator';
  
  // Shared Preferences Keys
  static const String prefUserLoggedIn = 'user_logged_in';
  static const String prefUserId = 'user_id';
  static const String prefUserEmail = 'user_email';
  static const String prefUserName = 'user_name';
  static const String prefUserType = 'user_type';
  
  // GraphHopper Server
  static const String graphHopperBaseUrl = 'http://127.0.0.1:8989'; // Changed to localhost for adb reverse
  static const String graphHopperApiKey = ''; // Not needed for local
  
  // Map Defaults
  static const double defaultMapZoom = 17.0;
  static const double campusLat = 11.320; // NITC approximate latitude
  static const double campusLng = 76.020; // NITC approximate longitude
  
  // Navigation
  static const double entryPointRadius = 20.0; // meters
}

class SharedPrefKeys {
  static const String recentSearches = 'recent_searches';
  static const String savedLocations = 'saved_locations';
}