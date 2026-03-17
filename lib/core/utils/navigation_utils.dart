import 'dart:math' as math;
import 'package:maplibre_gl/maplibre_gl.dart';

class NavigationUtils {
  /// Calculates the distance between two points in meters using the Haversine formula.
  static double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    double dLat = _degreesToRadians(point2.latitude - point1.latitude);
    double dLng = _degreesToRadians(point2.longitude - point1.longitude);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(point1.latitude)) *
            math.cos(_degreesToRadians(point2.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  /// Projects a point onto a line segment defined by two points.
  /// Returns the closest point on the segment to the given point.
  static LatLng projectPointOnSegment(LatLng point, LatLng start, LatLng end) {
    double x = point.longitude;
    double y = point.latitude;
    double x1 = start.longitude;
    double y1 = start.latitude;
    double x2 = end.longitude;
    double y2 = end.latitude;

    double dx = x2 - x1;
    double dy = y2 - y1;

    if (dx == 0 && dy == 0) return start;

    // t is the projection of (point - start) onto (end - start) normalized
    double t = ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy);

    if (t < 0) return start;
    if (t > 1) return end;

    return LatLng(y1 + t * dy, x1 + t * dx);
  }

  /// Finds the closest point on a polyline to a given point.
  /// Returns a [Map] with:
  /// - 'point': the snapped [LatLng]
  /// - 'distance': distance in meters from the original point to the snapped point
  /// - 'index': the index of the segment start point
  static Map<String, dynamic> snapToPolyline(LatLng point, List<LatLng> polyline) {
    if (polyline.isEmpty) return {'point': point, 'distance': double.infinity, 'index': -1};
    if (polyline.length == 1) {
      double dist = calculateDistance(point, polyline.first);
      return {'point': polyline.first, 'distance': dist, 'index': 0};
    }

    double minDistance = double.infinity;
    LatLng snappedPoint = polyline.first;
    int closestSegmentIndex = 0;

    for (int i = 0; i < polyline.length - 1; i++) {
      LatLng start = polyline[i];
      LatLng end = polyline[i + 1];

      LatLng projected = projectPointOnSegment(point, start, end);
      double distance = calculateDistance(point, projected);

      if (distance < minDistance) {
        minDistance = distance;
        snappedPoint = projected;
        closestSegmentIndex = i;
      }
    }

    return {
      'point': snappedPoint,
      'distance': minDistance,
      'index': closestSegmentIndex,
    };
  }

  /// Calculates the total distance of a polyline in meters.
  static double calculatePolylineDistance(List<LatLng> polyline) {
    double totalDistance = 0;
    for (int i = 0; i < polyline.length - 1; i++) {
      totalDistance += calculateDistance(polyline[i], polyline[i + 1]);
    }
    return totalDistance;
  }

  /// Calculates the distance from the start of the polyline to a specific point on the polyline.
  /// [snappedPoint] must be a point that lies on a segment of the polyline.
  /// [segmentIndex] is the index of the segment start point where [snappedPoint] lies.
  static double calculateDistanceTravelled(List<LatLng> polyline, LatLng snappedPoint, int segmentIndex) {
    if (polyline.isEmpty || segmentIndex < 0 || segmentIndex >= polyline.length) return 0;
    
    double distance = 0;
    for (int i = 0; i < segmentIndex; i++) {
      distance += calculateDistance(polyline[i], polyline[i + 1]);
    }
    
    distance += calculateDistance(polyline[segmentIndex], snappedPoint);
    return distance;
  }

  /// Applies a simple low-pass filter (smoothing) to coordinates.
  /// [previous] is the last smoothed coordinate.
  /// [current] is the new raw GPS coordinate.
  /// [alpha] is the smoothing factor (0 to 1). Lower means more smoothing.
  static LatLng smoothCoordinates(LatLng previous, LatLng current, {double alpha = 0.3}) {
    double smoothLat = (previous.latitude * (1 - alpha)) + (current.latitude * alpha);
    double smoothLng = (previous.longitude * (1 - alpha)) + (current.longitude * alpha);
    return LatLng(smoothLat, smoothLng);
  }

  /// Decodes an encoded polyline string into a list of LatLng points.
  /// Uses the Google Polyline Algorithm.
  static List<LatLng> decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }
}
