import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import '../core/constants/app_constants.dart';

class RouteInstruction {
  final String text;
  final double distance;
  final int time;
  final int sign;

  RouteInstruction({
    required this.text,
    required this.distance,
    required this.time,
    required this.sign,
  });

  factory RouteInstruction.fromJson(Map<String, dynamic> json) {
    return RouteInstruction(
      text: json['text'] ?? '',
      distance: (json['distance'] ?? 0.0).toDouble(),
      time: json['time'] ?? 0,
      sign: json['sign'] ?? 0,
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

  Future<NavigationRoute?> getRoute(LatLng start, LatLng end) async {
    try {
      final url = Uri.parse(
          '$baseUrl/route?point=${start.latitude},${start.longitude}&point=${end.latitude},${end.longitude}&profile=foot&points_encoded=false&instructions=true');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['paths'] != null && data['paths'].isNotEmpty) {
          final path = data['paths'][0];

          // Parse coordinates
          final coordsList = path['points']['coordinates'] as List<dynamic>;
          final List<LatLng> coordinates = coordsList.map((coord) {
            // Graphhopper returns [longitude, latitude]
            return LatLng(coord[1], coord[0]);
          }).toList();

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
        }
      } else {
        print('GraphHopper API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching GraphHopper route: $e');
    }
    return null;
  }
}
