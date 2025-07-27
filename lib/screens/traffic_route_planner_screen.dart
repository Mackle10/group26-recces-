import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/traffic_service.dart';
import '../services/location_service.dart';
import '../services/map_service.dart';
import '../services/proximity_service.dart';

class TrafficRoutePlannerScreen extends StatefulWidget {
  const TrafficRoutePlannerScreen({Key? key}) : super(key: key);

  @override
  State<TrafficRoutePlannerScreen> createState() => _TrafficRoutePlannerScreenState();
}

class _TrafficRoutePlannerScreenState extends State<TrafficRoutePlannerScreen> {
  final MapController _mapController = MapController();
  final TrafficService _trafficService = TrafficService();
  final LocationService _locationService = LocationService();
  final MapService _mapService = MapService();
  final ProximityService _proximityService = ProximityService();

  LatLng? _companyLocation;
  List<RequestWithDistance> _selectedRequests = [];
  List<RouteAlternative> _routeAlternatives = [];
  OptimalCollectionRoute? _optimalRoute;
  bool _isLoading = false;
  String _selectedTransport = 'driving-car';
  List<Marker> _markers = [];
  List<Polyline> _routeLines = [];
  List<TrafficIncident> _trafficIncidents = [];

  @override
  void initState() {
    super.initState();
    _loadCompanyData();
  }

  Future<void> _loadCompanyData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Load company location
        final companyDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (companyDoc.exists) {
          final data = companyDoc.data()!;
          final latitude = data['latitude'] as double?;
          final longitude = data['longitude'] as double?;
          
          if (latitude != null && longitude != null) {
            _companyLocation = LatLng(latitude, longitude);
            
            // Load assigned requests
            await _loadAssignedRequests();
            
            // Load traffic incidents
            await _loadTrafficIncidents();
            
            _updateMapDisplay();
          }
        }
      }
    } catch (e) {
      print('Error loading company data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAssignedRequests() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || _companyLocation == null) return;

      final requestsSnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('assignedCompanyId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'Pending')
          .get();

      final sortedRequests = _proximityService.sortRequestsByDistance(
        _companyLocation!,
        requestsSnapshot.docs,
      );

      setState(() {
        _selectedRequests = sortedRequests.take(10).toList(); // Limit to 10 for demo
      });
    } catch (e) {
      print('Error loading requests: $e');
    }
  }

  Future<void> _loadTrafficIncidents() async {
    if (_companyLocation == null) return;
    
    try {
      final incidents = await _trafficService.getTrafficIncidents(
        _companyLocation!,
        20.0, // 20km radius
      );
      
      setState(() {
        _trafficIncidents = incidents;
      });
    } catch (e) {
      print('Error loading traffic incidents: $e');
    }
  }

  void _updateMapDisplay() {
    if (_companyLocation == null) return;

    List<Marker> markers = [];

    // Company marker
    markers.add(_mapService.createCompanyMarker(
      _companyLocation!,
      title: 'Company Location',
    ));

    // Request markers
    for (var request in _selectedRequests) {
      markers.add(_mapService.createWasteMarker(
        request.location,
        title: 'Collection Point',
        onTap: () => _showRequestDetails(request),
      ));
    }

    // Traffic incident markers
    for (var incident in _trafficIncidents) {
      markers.add(_mapService.createCustomMarker(
        incident.location,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _getIncidentColor(incident.severity),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(
            _getIncidentIcon(incident.type),
            color: Colors.white,
            size: 16,
          ),
        ),
        onTap: () => _showIncidentDetails(incident),
      ));
    }

    setState(() {
      _markers = markers;
    });

    // Fit map to show all points
    if (_selectedRequests.isNotEmpty) {
      final allPoints = [_companyLocation!, ..._selectedRequests.map((r) => r.location)];
      _mapService.fitBounds(_mapController, allPoints);
    }
  }

  Future<void> _planOptimalRoute() async {
    if (_companyLocation == null || _selectedRequests.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final collectionPoints = _selectedRequests.map((r) => r.location).toList();
      
      // Get route alternatives for different transport modes
      final alternatives = await _trafficService.getRouteAlternatives(
        _companyLocation!,
        collectionPoints.first, // For demo, just use first point
        transportModes: ['driving-car', 'driving-hgv'],
      );

      // Get optimal collection route
      final optimalRoute = await _trafficService.getOptimalCollectionRoute(
        _companyLocation!,
        collectionPoints,
        preferredTransport: _selectedTransport,
      );

      setState(() {
        _routeAlternatives = alternatives;
        _optimalRoute = optimalRoute;
      });

      if (optimalRoute != null) {
        _displayOptimalRoute(optimalRoute);
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error planning route: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _displayOptimalRoute(OptimalCollectionRoute route) {
    final polyline = _mapService.createRoutePolyline(
      route.route,
      color: Colors.blue,
      strokeWidth: 4.0,
    );

    setState(() {
      _routeLines = [polyline];
    });

    // Fit map to show entire route
    _mapService.fitBounds(_mapController, route.route);
  }

  void _showRequestDetails(RequestWithDistance request) {
    final data = request.data;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Collection Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Distance: ${request.formattedDistance}'),
            Text('Address: ${data['address']}'),
            Text('Urgency: ${data['urgency']}'),
            Text('Date: ${data['date']} ${data['time']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showIncidentDetails(TrafficIncident incident) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Traffic Alert'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${incident.type.toString().split('.').last}'),
            Text('Severity: ${incident.severity.toString().split('.').last}'),
            Text('Description: ${incident.description}'),
            Text('Estimated Delay: ${incident.estimatedDelay.inMinutes} minutes'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getIncidentColor(TrafficSeverity severity) {
    switch (severity) {
      case TrafficSeverity.low:
        return Colors.yellow[700]!;
      case TrafficSeverity.moderate:
        return Colors.orange[700]!;
      case TrafficSeverity.high:
        return Colors.red[700]!;
      case TrafficSeverity.severe:
        return Colors.red[900]!;
    }
  }

  IconData _getIncidentIcon(TrafficIncidentType type) {
    switch (type) {
      case TrafficIncidentType.accident:
        return Icons.car_crash;
      case TrafficIncidentType.roadwork:
        return Icons.construction;
      case TrafficIncidentType.congestion:
        return Icons.traffic;
      case TrafficIncidentType.closure:
        return Icons.block;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Traffic-Aware Route Planner'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadCompanyData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Control panel
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: Column(
                    children: [
                      // Transport mode selector
                      Row(
                        children: [
                          Text('Transport: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: DropdownButton<String>(
                              value: _selectedTransport,
                              isExpanded: true,
                              items: [
                                DropdownMenuItem(
                                  value: 'driving-car',
                                  child: Row(
                                    children: [
                                      Icon(Icons.directions_car, size: 16),
                                      SizedBox(width: 8),
                                      Text('Small Vehicle (Car/Van)'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'driving-hgv',
                                  child: Row(
                                    children: [
                                      Icon(Icons.local_shipping, size: 16),
                                      SizedBox(width: 8),
                                      Text('Large Truck (HGV)'),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedTransport = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _selectedRequests.isNotEmpty ? _planOptimalRoute : null,
                              icon: Icon(Icons.route),
                              label: Text('Plan Route'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _loadTrafficIncidents,
                              icon: Icon(Icons.traffic),
                              label: Text('Check Traffic'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Map
                Expanded(
                  flex: 2,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: _mapService.getDefaultMapOptions(
                      center: _companyLocation ?? _locationService.getDefaultLocation(),
                      zoom: 12.0,
                    ),
                    children: [
                      _mapService.getOpenStreetMapTileLayer(),
                      if (_routeLines.isNotEmpty) PolylineLayer(polylines: _routeLines),
                      MarkerLayer(markers: _markers),
                    ],
                  ),
                ),

                // Route information panel
                if (_optimalRoute != null || _routeAlternatives.isNotEmpty)
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: Colors.grey[300]!)),
                      ),
                      child: _buildRouteInformation(),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_companyLocation != null) {
            _mapController.move(_companyLocation!, 13.0);
          }
        },
        child: Icon(Icons.my_location),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildRouteInformation() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_optimalRoute != null) ...[
            Text(
              'Optimal Route',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            _buildOptimalRouteCard(_optimalRoute!),
            SizedBox(height: 16),
          ],
          
          if (_routeAlternatives.isNotEmpty) ...[
            Text(
              'Transport Alternatives',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ..._routeAlternatives.map((alt) => _buildAlternativeCard(alt)),
          ],
        ],
      ),
    );
  }

  Widget _buildOptimalRouteCard(OptimalCollectionRoute route) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Distance: ${route.formattedDistance}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Time: ${route.formattedTime}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text('Stops: ${route.route.length - 2}'), // Exclude start and end
            Text('Traffic Impact: ${route.trafficAnalysis.trafficPercentage}%'),
            if (route.trafficAnalysis.estimatedDelay.inMinutes > 0)
              Text(
                'Traffic Delay: +${route.trafficAnalysis.estimatedDelay.inMinutes} min',
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 8),
            Text(
              route.trafficAnalysis.recommendation,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlternativeCard(RouteAlternative alternative) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: alternative.trafficColor,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(alternative.transportModeDisplay),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Traffic: ${alternative.trafficLevelDisplay}'),
            Text(alternative.recommendation.reason),
            if (alternative.recommendation.estimatedDelay.inMinutes > 0)
              Text(
                'Delay: +${alternative.recommendation.estimatedDelay.inMinutes} min',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ),
        trailing: Text(
          '#${alternative.recommendation.priority}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: alternative.recommendation.priority == 1 ? Colors.green : Colors.grey,
          ),
        ),
      ),
    );
  }
}