import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/navigation_utils.dart';

class RouteInstruction {
  final String text;
  final double distance;
  final int time;
  final int sign;
  final List<int> interval; // Start and end indices in the polyline

  RouteInstruction({
    required this.text,
    required this.distance,
    required this.time,
    required this.sign,
    required this.interval,
  });

  factory RouteInstruction.fromJson(Map<String, dynamic> json) {
    return RouteInstruction(
      text: json['text'] ?? '',
      distance: (json['distance'] ?? 0.0).toDouble(),
      time: json['time'] ?? 0,
      sign: json['sign'] ?? 0,
      interval: List<int>.from(json['interval'] ?? [0, 0]),
    );
  }
}

class NavigationRoute {
  final List<LatLng> coordinates;
  final double distance;
  final int time;
  final List<RouteInstruction> instructions;

  NavigationRoute({
    required this.coordinates,
    required this.distance,
    required this.time,
    required this.instructions,
  });
}

class GraphHopperService {
  final String baseUrl = AppConstants.graphHopperBaseUrl;

  /// Warms up the server by calling the /info endpoint.
  /// Retries up to 3 times if the request fails, which helps wake up Render's cold start.
  Future<bool> warmup() async {
    int retries = 3;
    while (retries > 0) {
      try {
        final url = Uri.parse('$baseUrl/info');
        final response = await http.get(url).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          debugPrint('GraphHopper Server warmed up successfully.');
          return true;
        }
      } catch (e) {
        debugPrint('Warmup attempt failed: $e. Retries left: ${retries - 1}');
      }
      retries--;
      if (retries > 0) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return false;
  }

  Future<NavigationRoute?> getRoute(LatLng start, LatLng end) async {
    try {
      final url = Uri.parse(
          '$baseUrl/route?'
          'point=${start.latitude},${start.longitude}&'
          'point=${end.latitude},${end.longitude}&'
          'profile=foot&'
          'locale=en&'
          'points_encoded=true&'
          'instructions=true');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['paths'] != null && data['paths'].isNotEmpty) {
          final path = data['paths'][0];

          // Decode polyline points
          final String encodedPoints = path['points'];
          final List<LatLng> coordinates = NavigationUtils.decodePolyline(encodedPoints);

          // Parse instructions
          List<RouteInstruction> instructions = [];
          if (path['instructions'] != null) {
             final instList = path['instructions'] as List<dynamic>;
             instructions = instList.map((i) => RouteInstruction.fromJson(i)).toList();
          }

          return NavigationRoute(
            coordinates: coordinates,
            distance: (path['distance'] ?? 0.0).toDouble(),
            time: path['time'] ?? 0,
            instructions: instructions,
          );
        } else {
            throw Exception('No path found in response');
        }
      } else {
        final body = response.body;
        print('GraphHopper API Error: ${response.statusCode} - $body');
        throw Exception('Server returned ${response.statusCode}: $body');
      }
    } catch (e) {
      print('Error fetching GraphHopper route: $e');
      rethrow;
    }
  }
}
