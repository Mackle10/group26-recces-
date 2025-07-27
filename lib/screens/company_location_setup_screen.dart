import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/location_service.dart';
import '../services/map_service.dart';
import '../services/geocoding_service.dart';
import '../widgets/location_picker_widget.dart';

class CompanyLocationSetupScreen extends StatefulWidget {
  const CompanyLocationSetupScreen({Key? key}) : super(key: key);

  @override
  State<CompanyLocationSetupScreen> createState() => _CompanyLocationSetupScreenState();
}

class _CompanyLocationSetupScreenState extends State<CompanyLocationSetupScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final MapService _mapService = MapService();
  final GeocodingService _geocodingService = GeocodingService();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _serviceRadiusController = TextEditingController();

  LatLng? _companyLocation;
  String _companyAddress = '';
  double _serviceRadius = 5000; // 5km default
  List<Marker> _markers = [];
  List<CircleMarker> _serviceAreas = [];
  bool _isLoading = false;
  bool _hasExistingLocation = false;

  @override
  void initState() {
    super.initState();
    _serviceRadiusController.text = '5';
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          final data = doc.data()!;
          final latitude = data['latitude'] as double?;
          final longitude = data['longitude'] as double?;
          
          if (latitude != null && longitude != null) {
            setState(() {
              _companyLocation = LatLng(latitude, longitude);
              _companyAddress = data['address'] ?? '';
              _serviceRadius = (data['serviceRadius'] ?? 5000).toDouble();
              _companyNameController.text = data['name'] ?? '';
              _serviceRadiusController.text = (_serviceRadius / 1000).toString();
              _hasExistingLocation = true;
            });
            
            _updateMapDisplay();
          }
        }
      }
    } catch (e) {
      print('Error loading existing data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openLocationPicker() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerWidget(
          initialLocation: _companyLocation,
          initialAddress: _companyAddress,
          onLocationSelected: (location, address) {
            setState(() {
              _companyLocation = location;
              _companyAddress = address;
            });
            _updateMapDisplay();
          },
        ),
      ),
    );
  }

  void _updateMapDisplay() {
    if (_companyLocation == null) return;

    // Update markers
    setState(() {
      _markers = [
        _mapService.createCompanyMarker(
          _companyLocation!,
          title: 'Company Location',
          onTap: () => _showLocationInfo(),
        ),
      ];

      // Update service area circle
      _serviceAreas = [
        _mapService.createServiceAreaCircle(
          _companyLocation!,
          _serviceRadius,
          color: Colors.green,
          opacity: 0.2,
        ),
      ];
    });

    // Center map on company location
    _mapController.move(_companyLocation!, 13.0);
  }

  void _showLocationInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Company Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Address: $_companyAddress'),
            SizedBox(height: 8),
            Text('Coordinates: ${_companyLocation!.latitude.toStringAsFixed(6)}, ${_companyLocation!.longitude.toStringAsFixed(6)}'),
            SizedBox(height: 8),
            Text('Service Radius: ${(_serviceRadius / 1000).toStringAsFixed(1)} km'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onServiceRadiusChanged(String value) {
    final radius = double.tryParse(value);
    if (radius != null && radius > 0) {
      setState(() {
        _serviceRadius = radius * 1000; // Convert km to meters
      });
      _updateMapDisplay();
    }
  }

  Future<void> _saveCompanyLocation() async {
    if (_companyLocation == null || _companyNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please provide company name and select location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'name': _companyNameController.text.trim(),
          'latitude': _companyLocation!.latitude,
          'longitude': _companyLocation!.longitude,
          'address': _companyAddress,
          'serviceRadius': _serviceRadius,
          'locationUpdatedAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Company location saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() => _hasExistingLocation = true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Company Location Setup'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Form section
                Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Company name
                      TextFormField(
                        controller: _companyNameController,
                        decoration: InputDecoration(
                          labelText: 'Company Name',
                          prefixIcon: Icon(Icons.business),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Location picker button
                      Container(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _openLocationPicker,
                          icon: Icon(Icons.location_on),
                          label: Text(
                            _companyAddress.isEmpty 
                                ? 'Select Company Location' 
                                : _companyAddress,
                            style: TextStyle(
                              color: _companyAddress.isEmpty ? Colors.grey[600] : Colors.black,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            alignment: Alignment.centerLeft,
                            side: BorderSide(
                              color: _companyLocation == null ? Colors.red : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Service radius
                      TextFormField(
                        controller: _serviceRadiusController,
                        decoration: InputDecoration(
                          labelText: 'Service Radius (km)',
                          prefixIcon: Icon(Icons.radio_button_unchecked),
                          border: OutlineInputBorder(),
                          helperText: 'Area where you provide waste collection services',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: _onServiceRadiusChanged,
                      ),
                      SizedBox(height: 16),

                      // Save button
                      Container(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveCompanyLocation,
                          icon: Icon(Icons.save),
                          label: Text(_hasExistingLocation ? 'Update Location' : 'Save Location'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Map section
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: FlutterMap(
                        mapController: _mapController,
                        options: _mapService.getDefaultMapOptions(
                          center: _companyLocation ?? _locationService.getDefaultLocation(),
                          zoom: 13.0,
                        ),
                        children: [
                          _mapService.getOpenStreetMapTileLayer(),
                          if (_serviceAreas.isNotEmpty)
                            CircleLayer(circles: _serviceAreas),
                          MarkerLayer(markers: _markers),
                        ],
                      ),
                    ),
                  ),
                ),

                // Info section
                if (_companyLocation != null)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    margin: EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service Area Information',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your company will be visible to clients within ${(_serviceRadius / 1000).toStringAsFixed(1)} km of your location.',
                          style: TextStyle(color: Colors.green[700]),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Service area: ~${(3.14159 * _serviceRadius * _serviceRadius / 1000000).toStringAsFixed(1)} km²',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
      floatingActionButton: _companyLocation != null
          ? FloatingActionButton(
              onPressed: () => _mapController.move(_companyLocation!, 15.0),
              child: Icon(Icons.center_focus_strong),
              backgroundColor: Colors.blue,
            )
          : null,
    );
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _serviceRadiusController.dispose();
    super.dispose();
  }
}