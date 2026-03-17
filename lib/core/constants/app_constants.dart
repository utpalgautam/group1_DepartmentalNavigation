class AppConstants {
  static const String appName = 'NITC Campus Navigator';
  
  // Shared Preferences Keys
  static const String prefUserLoggedIn = 'user_logged_in';
  static const String prefUserId = 'user_id';
  static const String prefUserEmail = 'user_email';
  static const String prefUserName = 'user_name';
  static const String prefUserType = 'user_type';
  
  // GraphHopper Server
  static const String graphHopperBaseUrl = 'https://group1-departmentalnavigation.onrender.com'; // Hosted on Render
  static const String graphHopperApiKey = ''; // Not needed for self-hostedf-hosted
  
  // Map Defaults
  static const double defaultMapZoom = 17.0;
  static const double campusLat = 11.319972; // NITC exact latitude
  static const double campusLng = 75.932639; // NITC exact longitude
  
  // Navigation
  static const double entryPointRadius = 20.0; // meters
}

class SharedPrefKeys {
  static const String recentSearches = 'recent_searches';
  static const String savedLocations = 'saved_locations';
}