import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/location_service.dart';
import '../services/map_service.dart';
import '../services/geocoding_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final MapService _mapService = MapService();
  final GeocodingService _geocodingService = GeocodingService();

  List<Marker> _markers = [];
  List<Polyline> _routes = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  LatLng? _currentLocation;

  // Data lists
  List<DocumentSnapshot> _requests = [];
  List<DocumentSnapshot> _companies = [];

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() async {
    await _getCurrentLocation();
    await _loadData();
    _updateMarkers();
    setState(() => _isLoading = false);
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        _currentLocation = _locationService.positionToLatLng(position);
      } else {
        _currentLocation = _locationService.getDefaultLocation();
      }
    } catch (e) {
      _currentLocation = _locationService.getDefaultLocation();
    }
  }

  Future<void> _loadData() async {
    try {
      // Load waste collection requests
      final requestsSnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .orderBy('submittedAt', descending: true)
          .limit(50)
          .get();
      
      // Load companies
      final companiesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userType', isEqualTo: 'Company')
          .get();

      setState(() {
        _requests = requestsSnapshot.docs;
        _companies = companiesSnapshot.docs;
      });
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  void _updateMarkers() {
    List<Marker> markers = [];

    // Add current location marker
    if (_currentLocation != null) {
      markers.add(_mapService.createCustomMarker(
        _currentLocation!,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(Icons.person, color: Colors.white, size: 16),
        ),
        onTap: () => _showLocationInfo('Your Location', 'Current location'),
      ));
    }

    // Add request markers
    if (_selectedFilter == 'All' || _selectedFilter == 'Requests') {
      for (var request in _requests) {
        final data = request.data() as Map<String, dynamic>;
        final latitude = data['latitude'] as double?;
        final longitude = data['longitude'] as double?;
        
        if (latitude != null && longitude != null) {
          final location = LatLng(latitude, longitude);
          final status = data['status'] ?? 'Pending';
          
          markers.add(_mapService.createWasteMarker(
            location,
            title: 'Request: ${data['address']}',
            isCollected: status == 'Completed',
            onTap: () => _showRequestInfo(request),
          ));
        }
      }
    }

    // Add company markers
    if (_selectedFilter == 'All' || _selectedFilter == 'Companies') {
      for (var company in _companies) {
        final data = company.data() as Map<String, dynamic>;
        final latitude = data['latitude'] as double?;
        final longitude = data['longitude'] as double?;
        
        if (latitude != null && longitude != null) {
          final location = LatLng(latitude, longitude);
          
          markers.add(_mapService.createCompanyMarker(
            location,
            title: 'Company: ${data['name']}',
            onTap: () => _showCompanyInfo(company),
          ));
        }
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  void _showLocationInfo(String title, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRequestInfo(DocumentSnapshot request) {
    final data = request.data() as Map<String, dynamic>;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Waste Collection Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Address', data['address'] ?? 'Unknown'),
            _buildInfoRow('Date', data['date'] ?? 'Unknown'),
            _buildInfoRow('Time', data['time'] ?? 'Unknown'),
            _buildInfoRow('Urgency', data['urgency'] ?? 'Normal'),
            _buildInfoRow('Status', data['status'] ?? 'Pending'),
            _buildInfoRow('Client', data['clientEmail'] ?? 'Unknown'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          if (_currentLocation != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showDirections(LatLng(data['latitude'], data['longitude']));
              },
              child: Text('Directions'),
            ),
        ],
      ),
    );
  }

  void _showCompanyInfo(DocumentSnapshot company) {
    final data = company.data() as Map<String, dynamic>;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Waste Management Company'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Name', data['name'] ?? 'Unknown'),
            _buildInfoRow('Email', data['email'] ?? 'Unknown'),
            _buildInfoRow('Type', data['userType'] ?? 'Company'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          if (_currentLocation != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showDirections(LatLng(data['latitude'], data['longitude']));
              },
              child: Text('Directions'),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showDirections(LatLng destination) async {
    if (_currentLocation == null) return;

    setState(() => _isLoading = true);

    try {
      // For now, show a straight line (you can implement routing later)
      final route = _mapService.getStraightLineRoute(_currentLocation!, destination);
      final polyline = _mapService.createRoutePolyline(route);

      setState(() {
        _routes = [polyline];
      });

      // Fit map to show both points
      _mapService.fitBounds(_mapController, [_currentLocation!, destination]);

      final distance = _locationService.getFormattedDistance(_currentLocation!, destination);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Distance: $distance (straight line)'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error calculating route: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _centerOnCurrentLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15.0);
    }
  }

  void _clearRoutes() {
    setState(() {
      _routes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Waste Collection Map'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
              _updateMarkers();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'All', child: Text('Show All')),
              PopupMenuItem(value: 'Requests', child: Text('Requests Only')),
              PopupMenuItem(value: 'Companies', child: Text('Companies Only')),
            ],
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_list),
                  SizedBox(width: 4),
                  Text(_selectedFilter, style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: _mapService.getDefaultMapOptions(
                    center: _currentLocation ?? _locationService.getDefaultLocation(),
                    zoom: 12.0,
                  ),
                  children: [
                    _mapService.getOpenStreetMapTileLayer(),
                    if (_routes.isNotEmpty) PolylineLayer(polylines: _routes),
                    MarkerLayer(markers: _markers),
                  ],
                ),
                
                // Legend
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Legend', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        _buildLegendItem(Icons.person, Colors.blue, 'Your Location'),
                        _buildLegendItem(Icons.delete, Colors.red, 'Pending Request'),
                        _buildLegendItem(Icons.delete, Colors.green, 'Completed Request'),
                        _buildLegendItem(Icons.business, Colors.green, 'Company'),
                      ],
                    ),
                  ),
                ),
                
                // Statistics
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Statistics', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Requests: ${_requests.length}'),
                        Text('Companies: ${_companies.length}'),
                        Text('Filter: $_selectedFilter'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_routes.isNotEmpty)
            FloatingActionButton(
              heroTag: "clear_routes",
              onPressed: _clearRoutes,
              child: Icon(Icons.clear),
              backgroundColor: Colors.red,
              mini: true,
            ),
          SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "refresh",
            onPressed: () {
              setState(() => _isLoading = true);
              _loadData().then((_) {
                _updateMarkers();
                setState(() => _isLoading = false);
              });
            },
            child: Icon(Icons.refresh),
            backgroundColor: Colors.orange,
            mini: true,
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "current_location",
            onPressed: _centerOnCurrentLocation,
            child: Icon(Icons.my_location),
            backgroundColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, Color color, String label) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}