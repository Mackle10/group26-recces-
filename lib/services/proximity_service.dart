import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_service.dart';

class ProximityService {
  static final ProximityService _instance = ProximityService._internal();
  factory ProximityService() => _instance;
  ProximityService._internal();

  final LocationService _locationService = LocationService();

  /// Sort requests by distance from company location
  List<RequestWithDistance> sortRequestsByDistance(
    LatLng companyLocation,
    List<DocumentSnapshot> requests,
  ) {
    List<RequestWithDistance> requestsWithDistance = [];

    for (var request in requests) {
      final data = request.data() as Map<String, dynamic>;
      final latitude = data['latitude'] as double?;
      final longitude = data['longitude'] as double?;

      if (latitude != null && longitude != null) {
        final requestLocation = LatLng(latitude, longitude);
        final distance = _locationService.calculateDistance(
          companyLocation,
          requestLocation,
        );

        requestsWithDistance.add(RequestWithDistance(
          request: request,
          distance: distance,
          location: requestLocation,
        ));
      }
    }

    // Sort by distance (nearest first)
    requestsWithDistance.sort((a, b) => a.distance.compareTo(b.distance));
    return requestsWithDistance;
  }

  /// Filter requests within company's service radius
  List<RequestWithDistance> getRequestsWithinServiceArea(
    LatLng companyLocation,
    double serviceRadiusInMeters,
    List<DocumentSnapshot> requests,
  ) {
    final sortedRequests = sortRequestsByDistance(companyLocation, requests);
    
    return sortedRequests
        .where((request) => request.distance <= serviceRadiusInMeters)
        .toList();
  }

  /// Get requests grouped by distance zones
  Map<String, List<RequestWithDistance>> groupRequestsByDistanceZones(
    LatLng companyLocation,
    List<DocumentSnapshot> requests,
  ) {
    final sortedRequests = sortRequestsByDistance(companyLocation, requests);
    
    Map<String, List<RequestWithDistance>> zones = {
      'Very Close (0-2km)': [],
      'Close (2-5km)': [],
      'Medium (5-10km)': [],
      'Far (10km+)': [],
    };

    for (var request in sortedRequests) {
      final distanceKm = request.distance / 1000;
      
      if (distanceKm <= 2) {
        zones['Very Close (0-2km)']!.add(request);
      } else if (distanceKm <= 5) {
        zones['Close (2-5km)']!.add(request);
      } else if (distanceKm <= 10) {
        zones['Medium (5-10km)']!.add(request);
      } else {
        zones['Far (10km+)']!.add(request);
      }
    }

    return zones;
  }

  /// Calculate optimal collection route using nearest neighbor algorithm
  List<RequestWithDistance> calculateOptimalRoute(
    LatLng companyLocation,
    List<RequestWithDistance> requests,
  ) {
    if (requests.isEmpty) return [];

    List<RequestWithDistance> route = [];
    List<RequestWithDistance> unvisited = List.from(requests);
    LatLng currentLocation = companyLocation;

    while (unvisited.isNotEmpty) {
      // Find nearest unvisited request
      RequestWithDistance nearest = unvisited.first;
      double nearestDistance = _locationService.calculateDistance(
        currentLocation,
        nearest.location,
      );

      for (var request in unvisited) {
        final distance = _locationService.calculateDistance(
          currentLocation,
          request.location,
        );
        if (distance < nearestDistance) {
          nearest = request;
          nearestDistance = distance;
        }
      }

      // Add to route and remove from unvisited
      route.add(nearest);
      unvisited.remove(nearest);
      currentLocation = nearest.location;
    }

    return route;
  }

  /// Get priority score for a request based on distance and urgency
  double calculatePriorityScore(
    LatLng companyLocation,
    DocumentSnapshot request,
  ) {
    final data = request.data() as Map<String, dynamic>;
    final latitude = data['latitude'] as double?;
    final longitude = data['longitude'] as double?;
    final urgency = data['urgency'] as String? ?? 'Normal';
    final status = data['status'] as String? ?? 'Pending';

    if (latitude == null || longitude == null) return 0;

    final requestLocation = LatLng(latitude, longitude);
    final distance = _locationService.calculateDistance(
      companyLocation,
      requestLocation,
    );

    // Base score (lower distance = higher score)
    double score = 10000 - distance; // Max distance assumed 10km

    // Urgency multiplier
    switch (urgency.toLowerCase()) {
      case 'urgent':
        score *= 2.0;
        break;
      case 'high':
        score *= 1.5;
        break;
      case 'normal':
        score *= 1.0;
        break;
      case 'low':
        score *= 0.8;
        break;
    }

    // Status penalty
    if (status == 'Completed') {
      score *= 0.1; // Very low priority for completed requests
    }

    // Time-based priority (older requests get higher priority)
    final submittedAt = data['submittedAt'] as Timestamp?;
    if (submittedAt != null) {
      final hoursSinceSubmission = DateTime.now()
          .difference(submittedAt.toDate())
          .inHours;
      score += hoursSinceSubmission * 10; // 10 points per hour
    }

    return score;
  }

  /// Sort requests by priority score (highest first)
  List<RequestWithPriority> sortRequestsByPriority(
    LatLng companyLocation,
    List<DocumentSnapshot> requests,
  ) {
    List<RequestWithPriority> requestsWithPriority = [];

    for (var request in requests) {
      final data = request.data() as Map<String, dynamic>;
      final latitude = data['latitude'] as double?;
      final longitude = data['longitude'] as double?;

      if (latitude != null && longitude != null) {
        final requestLocation = LatLng(latitude, longitude);
        final distance = _locationService.calculateDistance(
          companyLocation,
          requestLocation,
        );
        final priority = calculatePriorityScore(companyLocation, request);

        requestsWithPriority.add(RequestWithPriority(
          request: request,
          distance: distance,
          location: requestLocation,
          priorityScore: priority,
        ));
      }
    }

    // Sort by priority score (highest first)
    requestsWithPriority.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
    return requestsWithPriority;
  }

  /// Get nearby requests within a specific radius
  Future<List<RequestWithDistance>> getNearbyRequests(
    LatLng companyLocation,
    double radiusInMeters, {
    String? status,
    int limit = 50,
  }) async {
    try {
      Query query = FirebaseFirestore.instance
          .collection('requests')
          .orderBy('submittedAt', descending: true)
          .limit(limit);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();
      final requests = getRequestsWithinServiceArea(
        companyLocation,
        radiusInMeters,
        snapshot.docs,
      );

      return requests;
    } catch (e) {
      print('Error getting nearby requests: $e');
      return [];
    }
  }

  /// Calculate estimated collection time for a route
  Duration calculateEstimatedCollectionTime(
    List<RequestWithDistance> route, {
    Duration collectionTimePerStop = const Duration(minutes: 15),
    double averageSpeedKmh = 30.0,
  }) {
    if (route.isEmpty) return Duration.zero;

    // Calculate total travel time
    double totalDistanceKm = 0;
    for (int i = 0; i < route.length - 1; i++) {
      totalDistanceKm += _locationService.calculateDistance(
        route[i].location,
        route[i + 1].location,
      ) / 1000;
    }

    final travelTime = Duration(
      minutes: ((totalDistanceKm / averageSpeedKmh) * 60).round(),
    );

    // Add collection time for each stop
    final collectionTime = Duration(
      minutes: route.length * collectionTimePerStop.inMinutes,
    );

    return travelTime + collectionTime;
  }

  /// Get formatted distance string
  String getFormattedDistance(double distanceInMeters) {
    return _locationService.getFormattedDistance(
      LatLng(0, 0),
      LatLng(0, distanceInMeters / 111320), // Rough conversion
    );
  }
}

/// Data class for request with distance information
class RequestWithDistance {
  final DocumentSnapshot request;
  final double distance; // in meters
  final LatLng location;

  RequestWithDistance({
    required this.request,
    required this.distance,
    required this.location,
  });

  Map<String, dynamic> get data => request.data() as Map<String, dynamic>;
  String get id => request.id;
  
  String get formattedDistance {
    if (distance < 1000) {
      return '${distance.round()} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
  }
}

/// Data class for request with priority information
class RequestWithPriority extends RequestWithDistance {
  final double priorityScore;

  RequestWithPriority({
    required DocumentSnapshot request,
    required double distance,
    required LatLng location,
    required this.priorityScore,
  }) : super(request: request, distance: distance, location: location);

  String get priorityLevel {
    if (priorityScore > 15000) return 'Very High';
    if (priorityScore > 12000) return 'High';
    if (priorityScore > 8000) return 'Medium';
    if (priorityScore > 5000) return 'Low';
    return 'Very Low';
  }
}