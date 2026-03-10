import 'package:shared_preferences/shared_preferences.dart';

class OfflineStorageService {
  static const String _downloadedMapsKey = 'downloaded_maps';

  Future<Set<String>> getDownloadedBuildingIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_downloadedMapsKey) ?? [];
    return list.toSet();
  }

  Future<void> markAsDownloaded(String buildingId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_downloadedMapsKey) ?? [];
    if (!list.contains(buildingId)) {
      list.add(buildingId);
      await prefs.setStringList(_downloadedMapsKey, list);
    }
  }

  Future<void> removeDownloadedMap(String buildingId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_downloadedMapsKey) ?? [];
    if (list.contains(buildingId)) {
      list.remove(buildingId);
      await prefs.setStringList(_downloadedMapsKey, list);
    }
  }
}
