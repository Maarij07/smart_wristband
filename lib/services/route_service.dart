import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RouteService {
  static const String _osmRoutingUrl = 'https://router.project-osrm.org/route/v1/driving';

  /// Fetch route polyline between two points using OSRM (OpenStreetMap Routing Machine)
  /// No API key required - free service
  static Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    try {
      final url =
          '$_osmRoutingUrl/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson';

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Route request timeout'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final routes = json['routes'] as List?;

        if (routes == null || routes.isEmpty) {
          throw Exception('No routes found');
        }

        final geometry = routes[0]['geometry']['coordinates'] as List?;
        if (geometry == null || geometry.isEmpty) {
          throw Exception('Invalid geometry in response');
        }

        // Convert coordinates to LatLng
        return geometry
            .map((coord) => LatLng(
          coord[1] as double, // latitude
          coord[0] as double, // longitude
        ))
            .toList();
      } else {
        throw Exception('Failed to fetch route: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Route Service Error: $e');
      rethrow;
    }
  }

  /// Get multiple routes (for blue and pink polylines with slight offsets)
  /// Returns a tuple of (blueRoute, pinkRoute)
  static Future<(List<LatLng>, List<LatLng>)> getOffsetRoutes(
    LatLng start,
    LatLng end,
  ) async {
    try {
      // Fetch main route
      final mainRoute = await getRoute(start, end);

      if (mainRoute.length < 2) {
        return (mainRoute, mainRoute);
      }

      // Create slightly offset routes for visual effect
      const offsetDegrees = 0.0005; // Small offset for parallel lines

      // Blue route - offset to the left (negative longitude)
      final blueRoute = mainRoute
          .map((point) => LatLng(point.latitude, point.longitude - offsetDegrees))
          .toList();

      // Pink route - offset to the right (positive longitude)
      final pinkRoute = mainRoute
          .map((point) => LatLng(point.latitude, point.longitude + offsetDegrees))
          .toList();

      return (blueRoute, pinkRoute);
    } catch (e) {
      print('❌ Offset Routes Error: $e');
      rethrow;
    }
  }

  /// Get distance and duration between two points
  static Future<Map<String, dynamic>> getRouteInfo(LatLng start, LatLng end) async {
    try {
      final url =
          '$_osmRoutingUrl/${start.longitude},${start.latitude};${end.longitude},${end.latitude}';

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Route info request timeout'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final routes = json['routes'] as List?;

        if (routes == null || routes.isEmpty) {
          throw Exception('No routes found');
        }

        final route = routes[0];
        return {
          'distance': (route['distance'] as num).toDouble() / 1000, // Convert to km
          'duration': (route['duration'] as num).toInt(), // In seconds
          'distance_display': '${((route['distance'] as num).toDouble() / 1000).toStringAsFixed(1)} km',
          'duration_display': _formatDuration(route['duration'] as int),
        };
      } else {
        throw Exception('Failed to get route info: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Route Info Error: $e');
      return {
        'distance': 0.0,
        'duration': 0,
        'distance_display': 'Unknown',
        'duration_display': 'Unknown',
      };
    }
  }

  /// Format duration in seconds to readable format
  static String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      return '${minutes}m';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '${hours}h ${minutes}m';
    }
  }
}
