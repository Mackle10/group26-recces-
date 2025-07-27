import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';

class MapService {
  static final MapService _instance = MapService._internal();
  factory MapService() => _instance;
  MapService._internal();

  // OpenRouteService API (free tier: 2000 requests/day)
  static const String _openRouteServiceUrl = 'https://api.openrouteservice.org/v2';
  static const String _openRouteServiceKey = 'YOUR_ORS_API_KEY'; // You'll need to get this from openrouteservice.org

  /// Get default map options for Kampala, Uganda
  MapOptions getDefaultMapOptions({
    LatLng? center,
    double zoom = 13.0,
    Function(TapPosition, LatLng)? onTap,
    Function(MapPosition, bool)? onPositionChanged,
  }) {
    return MapOptions(
      center: center ?? LatLng(0.3476, 32.5825), // Kampala coordinates
      zoom: zoom,
      minZoom: 3.0,
      maxZoom: 18.0,
      onTap: onTap,
      onPositionChanged: onPositionChanged,
    );
  }

  /// Get OpenStreetMap tile layer
  TileLayer getOpenStreetMapTileLayer() {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.example.waste_management',
      maxZoom: 19,
      subdomains: const ['a', 'b', 'c'],
    );
  }

  /// Get alternative tile layer (CartoDB Positron - cleaner look)
  TileLayer getCartoDBTileLayer() {
    return TileLayer(
      urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.example.waste_management',
      maxZoom: 19,
      subdomains: const ['a', 'b', 'c', 'd'],
    );
  }

  /// Create a marker for home locations
  Marker createHomeMarker(LatLng position, {
    String? title,
    VoidCallback? onTap,
  }) {
    return Marker(
      point: position,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          child: Icon(
            Icons.home,
            color: Colors.blue,
            size: 30,
          ),
        ),
      ),
    );
  }

  /// Create a marker for company locations
  Marker createCompanyMarker(LatLng position, {
    String? title,
    VoidCallback? onTap,
  }) {
    return Marker(
      point: position,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          child: Icon(
            Icons.business,
            color: Colors.green,
            size: 30,
          ),
        ),
      ),
    );
  }

  /// Create a marker for waste collection points
  Marker createWasteMarker(LatLng position, {
    String? title,
    VoidCallback? onTap,
    bool isCollected = false,
  }) {
    return Marker(
      point: position,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          child: Icon(
            Icons.delete,
            color: isCollected ? Colors.green : Colors.red,
            size: 30,
          ),
        ),
      ),
    );
  }

  /// Create a custom marker with text
  Marker createCustomMarker(
    LatLng position, {
    required Widget child,
    VoidCallback? onTap,
  }) {
    return Marker(
      point: position,
      child: GestureDetector(
        onTap: onTap,
        child: child,
      ),
    );
  }

  /// Create a circle overlay for service areas
  CircleMarker createServiceAreaCircle(
    LatLng center,
    double radiusInMeters, {
    Color color = Colors.blue,
    double opacity = 0.3,
  }) {
    return CircleMarker(
      point: center,
      radius: radiusInMeters,
      color: color.withOpacity(opacity),
      borderColor: color,
      borderStrokeWidth: 2.0,
    );
  }

  /// Get route between two points using OpenRouteService
  Future<List<LatLng>?> getRoute(LatLng start, LatLng end, {
    String profile = 'driving-car', // driving-car, foot-walking, cycling-regular
  }) async {
    try {
      final url = '$_openRouteServiceUrl/directions/$profile';
      final coordinates = [
        [start.longitude, start.latitude],
        [end.longitude, end.latitude],
      ];

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': _openRouteServiceKey,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'coordinates': coordinates,
          'format': 'geojson',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates = data['features'][0]['geometry']['coordinates'] as List;
        
        return coordinates.map<LatLng>((coord) => 
          LatLng(coord[1].toDouble(), coord[0].toDouble())
        ).toList();
      } else {
        print('Route request failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting route: $e');
      return null;
    }
  }

  /// Get route without API (simple straight line for fallback)
  List<LatLng> getStraightLineRoute(LatLng start, LatLng end) {
    return [start, end];
  }

  /// Create polyline for route display
  Polyline createRoutePolyline(List<LatLng> points, {
    Color color = Colors.blue,
    double strokeWidth = 4.0,
  }) {
    return Polyline(
      points: points,
      color: color,
      strokeWidth: strokeWidth,
    );
  }

  /// Calculate optimal route for multiple stops (simple implementation)
  Future<List<LatLng>?> getOptimalRoute(
    LatLng start,
    List<LatLng> stops,
    LatLng end,
  ) async {
    try {
      // For now, we'll use a simple approach
      // In a production app, you'd use a proper TSP (Traveling Salesman Problem) solver
      List<LatLng> route = [start];
      route.addAll(stops);
      route.add(end);
      
      return route;
    } catch (e) {
      print('Error calculating optimal route: $e');
      return null;
    }
  }

  /// Get distance matrix between multiple points
  Future<Map<String, dynamic>?> getDistanceMatrix(
    List<LatLng> origins,
    List<LatLng> destinations,
  ) async {
    try {
      final url = '$_openRouteServiceUrl/matrix/driving-car';
      
      final locations = <List<double>>[];
      locations.addAll(origins.map((p) => [p.longitude, p.latitude]));
      locations.addAll(destinations.map((p) => [p.longitude, p.latitude]));

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': _openRouteServiceKey,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'locations': locations,
          'sources': List.generate(origins.length, (i) => i),
          'destinations': List.generate(destinations.length, (i) => origins.length + i),
          'metrics': ['distance', 'duration'],
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Distance matrix request failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting distance matrix: $e');
      return null;
    }
  }

  /// Create a polygon for service areas
  Polygon createServiceAreaPolygon(List<LatLng> points, {
    Color color = Colors.blue,
    double opacity = 0.3,
  }) {
    return Polygon(
      points: points,
      color: color.withOpacity(opacity),
      borderColor: color,
      borderStrokeWidth: 2.0,
    );
  }

  /// Get bounds for a list of points
  LatLngBounds getBoundsForPoints(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(
        LatLng(0.3476, 32.5825), // Kampala
        LatLng(0.3476, 32.5825),
      );
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    return LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
  }

  /// Fit map to show all points
  void fitBounds(MapController mapController, List<LatLng> points, {
    EdgeInsets padding = const EdgeInsets.all(20),
  }) {
    if (points.isEmpty) return;
    
    final bounds = getBoundsForPoints(points);
    mapController.fitBounds(bounds, options: FitBoundsOptions(
      padding: padding,
    ));
  }
}