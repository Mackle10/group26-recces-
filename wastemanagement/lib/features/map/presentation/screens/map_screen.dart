import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wastemanagement/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  LatLng _currentPosition = const LatLng(
    0.304833,
    32.554851,
  ); // Uganda coordinates (fallback)

  final Set<Marker> _markers = {};
  bool _isLoading = true;
  bool _isLocationLoading = true;
  List<Map<String, dynamic>> _companies = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadCompanyMarkers();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLocationLoading = true;
      });

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled')),
        );
        setState(() {
          _isLocationLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
          setState(() {
            _isLocationLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied'),
          ),
        );
        setState(() {
          _isLocationLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLocationLoading = false;
      });

      // Center map on user location
      if (mapController != null) {
        await mapController.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition, 13),
        );
      }
    } catch (e) {
      setState(() {
        _isLocationLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
    }
  }

  Future<void> _loadCompanyMarkers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Fetch companies from Firestore
      final QuerySnapshot companiesSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .where('isAvailable', isEqualTo: true)
          .get();

      final List<Map<String, dynamic>> companies = [];
      final Set<Marker> markers = {};

      for (var doc in companiesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Check if company has location data
        if (data['location'] != null) {
          final GeoPoint location = data['location'] as GeoPoint;
          final companyData = {
            'id': doc.id,
            'companyName': data['companyName'] ?? 'Unknown Company',
            'phoneNumber': data['phoneNumber'] ?? 'No Phone',
            'address': data['address'] ?? 'No Address',
            'wasteType': data['wasteType'] ?? 'General',
            'email': data['email'] ?? 'No Email',
            'latitude': location.latitude,
            'longitude': location.longitude,
          };

          companies.add(companyData);

          // Create marker for this company
          markers.add(
            Marker(
              markerId: MarkerId('company_${doc.id}'),
              position: LatLng(location.latitude, location.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
              infoWindow: InfoWindow(
                title: companyData['companyName'],
                snippet:
                    '${companyData['wasteType']} • ${companyData['phoneNumber']}',
              ),
              onTap: () => _showCompanyDetails(companyData),
            ),
          );
        }
      }

      setState(() {
        _companies = companies;
        _markers.clear();
        _markers.addAll(markers);
        _isLoading = false;
      });

      // Auto-center map to show all markers
      if (markers.isNotEmpty) {
        _centerMapOnMarkers();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading companies: $e')));
    }
  }

  void _centerMapOnMarkers() {
    if (_markers.isEmpty) return;

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    // Calculate bounds including user location
    final allPositions = <LatLng>[
      _currentPosition,
      ..._markers.map((marker) => marker.position),
    ];

    for (final position in allPositions) {
      minLat = min(minLat, position.latitude);
      maxLat = max(maxLat, position.latitude);
      minLng = min(minLng, position.longitude);
      maxLng = max(maxLng, position.longitude);
    }

    // Add padding to bounds
    const padding = 0.01; // About 1km
    final bounds = LatLngBounds(
      southwest: LatLng(minLat - padding, minLng - padding),
      northeast: LatLng(maxLat + padding, maxLng + padding),
    );

    mapController.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50), // 50px padding
    );
  }

  void _showCompanyDetails(Map<String, dynamic> companyData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCompanyDetailsSheet(companyData),
    );
  }

  Widget _buildCompanyDetailsSheet(Map<String, dynamic> companyData) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.8,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Company header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.business,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            companyData['companyName'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            companyData['wasteType'],
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Company details
                _buildDetailRow(
                  Icons.phone,
                  'Phone',
                  companyData['phoneNumber'],
                ),
                _buildDetailRow(Icons.email, 'Email', companyData['email']),
                _buildDetailRow(
                  Icons.location_on,
                  'Address',
                  companyData['address'],
                ),
                _buildDetailRow(
                  Icons.gps_fixed,
                  'Coordinates',
                  '${companyData['latitude'].toStringAsFixed(6)}, ${companyData['longitude'].toStringAsFixed(6)}',
                ),

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _callCompany(companyData['phoneNumber']),
                        icon: const Icon(Icons.phone),
                        label: const Text('Call'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _assignPickup(companyData),
                        icon: const Icon(Icons.assignment),
                        label: const Text('Assign Pickup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _callCompany(String phoneNumber) {
    // TODO: Implement phone call functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Calling $phoneNumber...')));
  }

  Future<void> _assignPickup(Map<String, dynamic> companyData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to assign pickup')),
        );
        return;
      }

      // Create pickup assignment
      await FirebaseFirestore.instance.collection('pickup_assignments').add({
        'userId': user.uid,
        'companyId': companyData['id'],
        'companyName': companyData['companyName'],
        'userEmail': user.email,
        'status': 'pending',
        'assignedAt': FieldValue.serverTimestamp(),
        'wasteType': companyData['wasteType'],
        'userLocation': null, // TODO: Get user location
        'companyLocation': GeoPoint(
          companyData['latitude'],
          companyData['longitude'],
        ),
      });

      // Update company's assigned pickups count
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyData['id'])
          .update({'assignedPickups': FieldValue.increment(1)});

      Navigator.pop(context); // Close bottom sheet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pickup assigned to ${companyData['companyName']}'),
          backgroundColor: AppColors.lightGreen1,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error assigning pickup: $e')));
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    // Center map on user location if available
    if (!_isLocationLoading &&
        _currentPosition != const LatLng(0.304833, 32.554851)) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 13),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waste Collection Map'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCompanyMarkers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 13,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),

          // Map legend
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Legend',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      const Text(
                        'Waste Companies',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.my_location, color: Colors.blue, size: 16),
                      const SizedBox(width: 4),
                      const Text(
                        'Your Location',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
