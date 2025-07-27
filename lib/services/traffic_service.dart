import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'location_service.dart';

class TrafficService {
  static final TrafficService _instance = TrafficService._internal();
  factory TrafficService() => _instance;
  TrafficService._internal();

  final LocationService _locationService = LocationService();

  // OpenRouteService API for traffic-aware routing (free tier: 2000 requests/day)
  static const String _openRouteServiceUrl = 'https://api.openrouteservice.org/v2';
  static const String _openRouteServiceKey = 'YOUR_ORS_API_KEY'; // Get from openrouteservice.org

  /// Get traffic-aware route with real-time conditions
  Future<TrafficAwareRoute?> getTrafficAwareRoute(
    LatLng start,
    LatLng end, {
    String profile = 'driving-car', // driving-car, driving-hgv (heavy goods vehicle)
    bool avoidTolls = false,
    bool avoidHighways = false,
  }) async {
    try {
      final url = '$_openRouteServiceUrl/directions/$profile';
      final coordinates = [
        [start.longitude, start.latitude],
        [end.longitude, end.latitude],
      ];

      final requestBody = {
        'coordinates': coordinates,
        'format': 'geojson',
        'instructions': true,
        'elevation': false,
        'extra_info': ['roadaccessrestrictions', 'tollways', 'surface'],
        'options': {
          'avoid_features': [
            if (avoidTolls) 'tollways',
            if (avoidHighways) 'highways',
          ],
          'profile_params': {
            'restrictions': {
              'length': profile == 'driving-hgv' ? 12.0 : null,
              'width': profile == 'driving-hgv' ? 2.5 : null,
              'height': profile == 'driving-hgv' ? 4.0 : null,
              'weight': profile == 'driving-hgv' ? 40.0 : null,
            }
          }
        }
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': _openRouteServiceKey,
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TrafficAwareRoute.fromJson(data);
      } else {
        print('Traffic route request failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting traffic-aware route: $e');
      return null;
    }
  }

  /// Get multiple route alternatives with traffic analysis
  Future<List<RouteAlternative>> getRouteAlternatives(
    LatLng start,
    LatLng end, {
    List<String> transportModes = const ['driving-car', 'driving-hgv'],
  }) async {
    List<RouteAlternative> alternatives = [];

    for (String mode in transportModes) {
      final route = await getTrafficAwareRoute(start, end, profile: mode);
      if (route != null) {
        final trafficLevel = await _analyzeTrafficLevel(route);
        alternatives.add(RouteAlternative(
          route: route,
          transportMode: mode,
          trafficLevel: trafficLevel,
          recommendation: _getTransportRecommendation(mode, trafficLevel, route),
        ));
      }
    }

    // Sort by total time (including traffic delays)
    alternatives.sort((a, b) => a.totalTimeWithTraffic.compareTo(b.totalTimeWithTraffic));
    return alternatives;
  }

  /// Analyze traffic level based on route characteristics
  Future<TrafficLevel> _analyzeTrafficLevel(TrafficAwareRoute route) async {
    // Analyze based on time of day, road types, and distance
    final currentHour = DateTime.now().hour;
    
    // Peak hours in Kampala: 7-9 AM, 5-7 PM
    bool isPeakHour = (currentHour >= 7 && currentHour <= 9) || 
                      (currentHour >= 17 && currentHour <= 19);
    
    // Weekend traffic is generally lighter
    bool isWeekend = DateTime.now().weekday >= 6;
    
    // Analyze road types from route segments
    int highwaySegments = 0;
    int citySegments = 0;
    
    for (var segment in route.segments) {
      if (segment.roadType.contains('highway') || segment.roadType.contains('trunk')) {
        highwaySegments++;
      } else if (segment.roadType.contains('primary') || segment.roadType.contains('secondary')) {
        citySegments++;
      }
    }
    
    // Calculate traffic score
    double trafficScore = 0.0;
    
    if (isPeakHour && !isWeekend) trafficScore += 3.0;
    if (citySegments > highwaySegments) trafficScore += 2.0;
    if (route.distance > 10000) trafficScore += 1.0; // Long routes more likely to hit traffic
    
    // Determine traffic level
    if (trafficScore >= 4.0) return TrafficLevel.heavy;
    if (trafficScore >= 2.5) return TrafficLevel.moderate;
    if (trafficScore >= 1.0) return TrafficLevel.light;
    return TrafficLevel.free;
  }

  /// Get transport recommendation based on traffic and route
  TransportRecommendation _getTransportRecommendation(
    String transportMode,
    TrafficLevel trafficLevel,
    TrafficAwareRoute route,
  ) {
    String vehicle = transportMode == 'driving-hgv' ? 'Large Truck' : 'Small Vehicle';
    String reason = '';
    int priority = 0;

    switch (trafficLevel) {
      case TrafficLevel.free:
        reason = 'Clear roads - optimal conditions';
        priority = transportMode == 'driving-car' ? 1 : 2;
        break;
      case TrafficLevel.light:
        reason = 'Light traffic - good conditions';
        priority = transportMode == 'driving-car' ? 1 : 2;
        break;
      case TrafficLevel.moderate:
        if (transportMode == 'driving-hgv') {
          reason = 'Moderate traffic - large vehicle may cause delays';
          priority = 3;
        } else {
          reason = 'Moderate traffic - small vehicle recommended';
          priority = 1;
        }
        break;
      case TrafficLevel.heavy:
        if (transportMode == 'driving-hgv') {
          reason = 'Heavy traffic - avoid large vehicles';
          priority = 4;
        } else {
          reason = 'Heavy traffic - use small, maneuverable vehicle';
          priority = 2;
        }
        break;
    }

    return TransportRecommendation(
      vehicle: vehicle,
      reason: reason,
      priority: priority,
      estimatedDelay: _calculateTrafficDelay(trafficLevel, route.duration),
    );
  }

  /// Calculate estimated delay due to traffic
  Duration _calculateTrafficDelay(TrafficLevel trafficLevel, Duration baseDuration) {
    double multiplier;
    switch (trafficLevel) {
      case TrafficLevel.free:
        multiplier = 1.0;
        break;
      case TrafficLevel.light:
        multiplier = 1.2;
        break;
      case TrafficLevel.moderate:
        multiplier = 1.5;
        break;
      case TrafficLevel.heavy:
        multiplier = 2.0;
        break;
    }
    
    final totalDuration = Duration(
      milliseconds: (baseDuration.inMilliseconds * multiplier).round(),
    );
    
    return totalDuration - baseDuration;
  }

  /// Get optimal collection route considering traffic for multiple stops
  Future<OptimalCollectionRoute?> getOptimalCollectionRoute(
    LatLng companyLocation,
    List<LatLng> collectionPoints, {
    String preferredTransport = 'driving-car',
  }) async {
    if (collectionPoints.isEmpty) return null;

    try {
      // Use matrix API to get distances and times between all points
      final allPoints = [companyLocation, ...collectionPoints];
      final matrix = await _getDistanceMatrix(allPoints, preferredTransport);
      
      if (matrix == null) return null;

      // Apply nearest neighbor algorithm with traffic considerations
      List<int> route = [0]; // Start at company (index 0)
      List<bool> visited = List.filled(allPoints.length, false);
      visited[0] = true;
      
      int currentPoint = 0;
      double totalDistance = 0;
      Duration totalTime = Duration.zero;
      
      while (route.length < allPoints.length) {
        int nearestPoint = -1;
        double nearestTime = double.infinity;
        
        for (int i = 1; i < allPoints.length; i++) {
          if (!visited[i]) {
            final timeToPoint = matrix.durations[currentPoint][i];
            if (timeToPoint < nearestTime) {
              nearestTime = timeToPoint;
              nearestPoint = i;
            }
          }
        }
        
        if (nearestPoint != -1) {
          route.add(nearestPoint);
          visited[nearestPoint] = true;
          totalDistance += matrix.distances[currentPoint][nearestPoint];
          totalTime += Duration(seconds: nearestTime.round());
          currentPoint = nearestPoint;
        }
      }
      
      // Add return to company
      totalDistance += matrix.distances[currentPoint][0];
      totalTime += Duration(seconds: matrix.durations[currentPoint][0].round());
      route.add(0);
      
      return OptimalCollectionRoute(
        route: route.map((i) => allPoints[i]).toList(),
        totalDistance: totalDistance,
        totalTime: totalTime,
        transportMode: preferredTransport,
        trafficAnalysis: await _analyzeRouteTraffic(route, allPoints),
      );
      
    } catch (e) {
      print('Error calculating optimal collection route: $e');
      return null;
    }
  }

  /// Get distance matrix for multiple points
  Future<DistanceMatrix?> _getDistanceMatrix(
    List<LatLng> points,
    String profile,
  ) async {
    try {
      final url = '$_openRouteServiceUrl/matrix/$profile';
      final locations = points.map((p) => [p.longitude, p.latitude]).toList();

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': _openRouteServiceKey,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'locations': locations,
          'metrics': ['distance', 'duration'],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DistanceMatrix.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting distance matrix: $e');
      return null;
    }
  }

  /// Analyze traffic for entire route
  Future<RouteTrafficAnalysis> _analyzeRouteTraffic(
    List<int> routeIndices,
    List<LatLng> points,
  ) async {
    int heavyTrafficSegments = 0;
    int totalSegments = routeIndices.length - 1;
    Duration totalDelay = Duration.zero;
    
    for (int i = 0; i < routeIndices.length - 1; i++) {
      final start = points[routeIndices[i]];
      final end = points[routeIndices[i + 1]];
      
      // Simulate traffic analysis for each segment
      final distance = _locationService.calculateDistance(start, end);
      final baseTime = Duration(minutes: (distance / 1000 / 30 * 60).round()); // 30 km/h average
      
      final trafficLevel = await _analyzeTrafficLevel(
        TrafficAwareRoute(
          coordinates: [start, end],
          distance: distance,
          duration: baseTime,
          segments: [RouteSegment(roadType: 'primary', distance: distance)],
        ),
      );
      
      if (trafficLevel == TrafficLevel.heavy || trafficLevel == TrafficLevel.moderate) {
        heavyTrafficSegments++;
      }
      
      totalDelay += _calculateTrafficDelay(trafficLevel, baseTime);
    }
    
    return RouteTrafficAnalysis(
      totalSegments: totalSegments,
      heavyTrafficSegments: heavyTrafficSegments,
      trafficPercentage: (heavyTrafficSegments / totalSegments * 100).round(),
      estimatedDelay: totalDelay,
      recommendation: heavyTrafficSegments > totalSegments / 2 
          ? 'Consider using smaller vehicles or alternative timing'
          : 'Route conditions are acceptable',
    );
  }

  /// Get real-time traffic updates for a specific area
  Future<List<TrafficIncident>> getTrafficIncidents(
    LatLng center,
    double radiusKm,
  ) async {
    // This would integrate with traffic APIs like TomTom, HERE, or local traffic services
    // For now, return simulated incidents based on common Kampala traffic patterns
    return _getSimulatedTrafficIncidents(center, radiusKm);
  }

  /// Simulate traffic incidents for demonstration
  List<TrafficIncident> _getSimulatedTrafficIncidents(LatLng center, double radiusKm) {
    final incidents = <TrafficIncident>[];
    final currentHour = DateTime.now().hour;
    
    // Simulate common traffic patterns in Kampala
    if (currentHour >= 7 && currentHour <= 9) {
      incidents.add(TrafficIncident(
        location: LatLng(0.3476, 32.5825), // Central Kampala
        type: TrafficIncidentType.congestion,
        severity: TrafficSeverity.high,
        description: 'Heavy morning traffic on Kampala Road',
        estimatedDelay: Duration(minutes: 15),
      ));
    }
    
    if (currentHour >= 17 && currentHour <= 19) {
      incidents.add(TrafficIncident(
        location: LatLng(0.3367, 32.5739), // Entebbe Road
        type: TrafficIncidentType.congestion,
        severity: TrafficSeverity.moderate,
        description: 'Evening rush hour on Entebbe Road',
        estimatedDelay: Duration(minutes: 20),
      ));
    }
    
    return incidents.where((incident) {
      final distance = _locationService.calculateDistance(center, incident.location);
      return distance <= radiusKm * 1000;
    }).toList();
  }
}

// Data classes for traffic information

enum TrafficLevel { free, light, moderate, heavy }
enum TrafficIncidentType { accident, roadwork, congestion, closure }
enum TrafficSeverity { low, moderate, high, severe }

class TrafficAwareRoute {
  final List<LatLng> coordinates;
  final double distance; // in meters
  final Duration duration;
  final List<RouteSegment> segments;

  TrafficAwareRoute({
    required this.coordinates,
    required this.distance,
    required this.duration,
    required this.segments,
  });

  factory TrafficAwareRoute.fromJson(Map<String, dynamic> json) {
    final features = json['features'] as List;
    final geometry = features[0]['geometry'];
    final properties = features[0]['properties'];
    final segments = properties['segments'] as List;

    final coordinates = (geometry['coordinates'] as List)
        .map<LatLng>((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
        .toList();

    return TrafficAwareRoute(
      coordinates: coordinates,
      distance: properties['summary']['distance'].toDouble(),
      duration: Duration(seconds: properties['summary']['duration'].round()),
      segments: segments.map<RouteSegment>((seg) => RouteSegment.fromJson(seg)).toList(),
    );
  }
}

class RouteSegment {
  final String roadType;
  final double distance;

  RouteSegment({required this.roadType, required this.distance});

  factory RouteSegment.fromJson(Map<String, dynamic> json) {
    return RouteSegment(
      roadType: json['road_type'] ?? 'unknown',
      distance: json['distance']?.toDouble() ?? 0.0,
    );
  }
}

class RouteAlternative {
  final TrafficAwareRoute route;
  final String transportMode;
  final TrafficLevel trafficLevel;
  final TransportRecommendation recommendation;

  RouteAlternative({
    required this.route,
    required this.transportMode,
    required this.trafficLevel,
    required this.recommendation,
  });

  Duration get totalTimeWithTraffic => 
      route.duration + recommendation.estimatedDelay;

  String get transportModeDisplay {
    switch (transportMode) {
      case 'driving-car':
        return 'Small Vehicle';
      case 'driving-hgv':
        return 'Large Truck';
      default:
        return transportMode;
    }
  }

  String get trafficLevelDisplay {
    switch (trafficLevel) {
      case TrafficLevel.free:
        return 'Free Flow';
      case TrafficLevel.light:
        return 'Light Traffic';
      case TrafficLevel.moderate:
        return 'Moderate Traffic';
      case TrafficLevel.heavy:
        return 'Heavy Traffic';
    }
  }

  Color get trafficColor {
    switch (trafficLevel) {
      case TrafficLevel.free:
        return const Color(0xFF4CAF50); // Green
      case TrafficLevel.light:
        return const Color(0xFF8BC34A); // Light Green
      case TrafficLevel.moderate:
        return const Color(0xFFFF9800); // Orange
      case TrafficLevel.heavy:
        return const Color(0xFFF44336); // Red
    }
  }
}

class TransportRecommendation {
  final String vehicle;
  final String reason;
  final int priority; // 1 = best, higher = worse
  final Duration estimatedDelay;

  TransportRecommendation({
    required this.vehicle,
    required this.reason,
    required this.priority,
    required this.estimatedDelay,
  });
}

class OptimalCollectionRoute {
  final List<LatLng> route;
  final double totalDistance;
  final Duration totalTime;
  final String transportMode;
  final RouteTrafficAnalysis trafficAnalysis;

  OptimalCollectionRoute({
    required this.route,
    required this.totalDistance,
    required this.totalTime,
    required this.transportMode,
    required this.trafficAnalysis,
  });

  String get formattedDistance {
    if (totalDistance < 1000) {
      return '${totalDistance.round()} m';
    } else {
      return '${(totalDistance / 1000).toStringAsFixed(1)} km';
    }
  }

  String get formattedTime {
    final hours = totalTime.inHours;
    final minutes = totalTime.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

class RouteTrafficAnalysis {
  final int totalSegments;
  final int heavyTrafficSegments;
  final int trafficPercentage;
  final Duration estimatedDelay;
  final String recommendation;

  RouteTrafficAnalysis({
    required this.totalSegments,
    required this.heavyTrafficSegments,
    required this.trafficPercentage,
    required this.estimatedDelay,
    required this.recommendation,
  });
}

class DistanceMatrix {
  final List<List<double>> distances;
  final List<List<double>> durations;

  DistanceMatrix({required this.distances, required this.durations});

  factory DistanceMatrix.fromJson(Map<String, dynamic> json) {
    final distances = (json['distances'] as List)
        .map<List<double>>((row) => (row as List).map<double>((d) => d.toDouble()).toList())
        .toList();
    
    final durations = (json['durations'] as List)
        .map<List<double>>((row) => (row as List).map<double>((d) => d.toDouble()).toList())
        .toList();

    return DistanceMatrix(distances: distances, durations: durations);
  }
}

class TrafficIncident {
  final LatLng location;
  final TrafficIncidentType type;
  final TrafficSeverity severity;
  final String description;
  final Duration estimatedDelay;

  TrafficIncident({
    required this.location,
    required this.type,
    required this.severity,
    required this.description,
    required this.estimatedDelay,
  });
}