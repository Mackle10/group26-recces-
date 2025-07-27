import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/traffic_service.dart';
import '../services/location_service.dart';
import '../services/map_service.dart';
import '../services/proximity_service.dart';

class IndividualRouteScreen extends StatefulWidget {
  final LatLng companyLocation;
  final RequestWithDistance requestWithDistance;

  const IndividualRouteScreen({
    Key? key,
    required this.companyLocation,
    required this.requestWithDistance,
  }) : super(key: key);

  @override
  State<IndividualRouteScreen> createState() => _IndividualRouteScreenState();
}

class _IndividualRouteScreenState extends State<IndividualRouteScreen> {
  final MapController _mapController = MapController();
  final TrafficService _trafficService = TrafficService();
  final LocationService _locationService = LocationService();
  final MapService _mapService = MapService();

  List<RouteAlternative> _routeAlternatives = [];
  bool _isLoading = true;
  List<Marker> _markers = [];
  List<Polyline> _routeLines = [];

  @override
  void initState() {
    super.initState();
    _loadRouteData();
  }

  Future<void> _loadRouteData() async {
    setState(() => _isLoading = true);

    try {
      // Get route alternatives with traffic analysis
      final routeAlternatives = await _trafficService.getRouteAlternatives(
        widget.companyLocation,
        widget.requestWithDistance.location,
        transportModes: ['driving-car', 'driving-hgv'],
      );

      setState(() {
        _routeAlternatives = routeAlternatives;
      });

      _updateMapDisplay();
      
      // Show the best route on map
      if (routeAlternatives.isNotEmpty) {
        _displayRoute(routeAlternatives.first);
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading route: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateMapDisplay() {
    List<Marker> markers = [];

    // Company marker
    markers.add(_mapService.createCompanyMarker(
      widget.companyLocation,
      title: 'Company Location',
    ));

    // Home marker
    markers.add(_mapService.createHomeMarker(
      widget.requestWithDistance.location,
      title: 'Home Location',
    ));

    setState(() {
      _markers = markers;
    });

    // Fit map to show both points
    _mapService.fitBounds(_mapController, [
      widget.companyLocation,
      widget.requestWithDistance.location,
    ]);
  }

  void _displayRoute(RouteAlternative alternative) {
    final polyline = _mapService.createRoutePolyline(
      alternative.route.coordinates,
      color: alternative.trafficColor,
      strokeWidth: 4.0,
    );

    setState(() {
      _routeLines = [polyline];
    });
  }

  Future<void> _markAsCompleted() async {
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestWithDistance.id)
          .update({'status': 'Completed'});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request marked as completed!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true); // Return true to indicate completion
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.requestWithDistance.data;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Route to Home'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadRouteData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Request details header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.home, color: Colors.blue[700]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        data['address'] ?? 'Unknown Address',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.requestWithDistance.formattedDistance,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip('Client', data['clientEmail'] ?? 'Unknown', Icons.person),
                    SizedBox(width: 8),
                    _buildInfoChip('Urgency', data['urgency'] ?? 'Normal', Icons.priority_high),
                    SizedBox(width: 8),
                    _buildInfoChip('Time', '${data['date']} ${data['time']}', Icons.schedule),
                  ],
                ),
              ],
            ),
          ),

          // Map
          Expanded(
            flex: 2,
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading route information...'),
                      ],
                    ),
                  )
                : FlutterMap(
                    mapController: _mapController,
                    options: _mapService.getDefaultMapOptions(
                      center: widget.companyLocation,
                      zoom: 12.0,
                    ),
                    children: [
                      _mapService.getOpenStreetMapTileLayer(),
                      if (_routeLines.isNotEmpty) PolylineLayer(polylines: _routeLines),
                      MarkerLayer(markers: _markers),
                    ],
                  ),
          ),

          // Transport options
          if (_routeAlternatives.isNotEmpty)
            Expanded(
              flex: 1,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transport Options',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _routeAlternatives.length,
                        itemBuilder: (context, index) {
                          final alternative = _routeAlternatives[index];
                          final isRecommended = index == 0;
                          
                          return GestureDetector(
                            onTap: () => _displayRoute(alternative),
                            child: Card(
                              margin: EdgeInsets.only(bottom: 8),
                              elevation: isRecommended ? 4 : 1,
                              color: isRecommended ? Colors.green[50] : null,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: alternative.trafficColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            alternative.transportModeDisplay,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isRecommended ? Colors.green[800] : null,
                                            ),
                                          ),
                                        ),
                                        if (isRecommended)
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'BEST',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildMetric(
                                          'Distance',
                                          '${(alternative.route.distance / 1000).toStringAsFixed(1)} km',
                                          Icons.straighten,
                                        ),
                                        _buildMetric(
                                          'Time',
                                          '${alternative.totalTimeWithTraffic.inMinutes} min',
                                          Icons.access_time,
                                        ),
                                        _buildMetric(
                                          'Traffic',
                                          alternative.trafficLevelDisplay,
                                          Icons.traffic,
                                          color: alternative.trafficColor,
                                        ),
                                      ],
                                    ),
                                    
                                    SizedBox(height: 8),
                                    
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.lightbulb, color: Colors.blue[700], size: 14),
                                          SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              alternative.recommendation.reason,
                                              style: TextStyle(
                                                color: Colors.blue[700],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "center_map",
            onPressed: () {
              _mapService.fitBounds(_mapController, [
                widget.companyLocation,
                widget.requestWithDistance.location,
              ]);
            },
            child: Icon(Icons.center_focus_strong),
            backgroundColor: Colors.blue,
            mini: true,
          ),
          SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: "mark_complete",
            onPressed: _markAsCompleted,
            icon: Icon(Icons.check),
            label: Text('Mark Complete'),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blue[600]),
          SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.grey[600], size: 18),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}