import 'dart:math';
import 'dart:async';
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
    // Use microtask to avoid blocking the main thread
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMap();
    });
  }

  Future<void> _initializeMap() async {
    // Run location and marker loading in parallel
    await Future.wait([_getCurrentLocation(), _loadCompanyMarkers()]);
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (!mounted) return;

      setState(() {
        _isLocationLoading = true;
      });

      // Use lower accuracy for faster response
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled')),
          );
          setState(() {
            _isLocationLoading = false;
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')),
            );
            setState(() {
              _isLocationLoading = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied'),
            ),
          );
          setState(() {
            _isLocationLoading = false;
          });
        }
        return;
      }

      // Use medium accuracy for better performance
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10), // Add timeout
      );

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLocationLoading = false;
        });

        // Center map on user location with delay to avoid blocking
        if (mapController != null) {
          Future.delayed(const Duration(milliseconds: 100), () async {
            if (mounted && mapController != null) {
              await mapController.animateCamera(
                CameraUpdate.newLatLngZoom(_currentPosition, 13),
              );
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLocationLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      }
    }
  }

  Future<void> _loadCompanyMarkers() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Add timeout to prevent hanging
      final QuerySnapshot companiesSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .where('isAvailable', isEqualTo: true)
          .limit(20) // Reduced limit for better performance
          .get()
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Company loading timed out');
            },
          );

      final List<Map<String, dynamic>> companies = [];
      final Set<Marker> markers = {};

      // Process companies in smaller batches
      int processedCount = 0;
      for (var doc in companiesSnapshot.docs) {
        if (!mounted) return; // Check if widget is still mounted

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

        // Update UI periodically to prevent blocking
        processedCount++;
        if (processedCount % 5 == 0 && mounted) {
          setState(() {
            _companies = companies;
            _markers.clear();
            _markers.addAll(markers);
          });

          // Small delay to allow UI updates
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }

      // Final state update
      if (mounted) {
        setState(() {
          _companies = companies;
          _markers.clear();
          _markers.addAll(markers);
          _isLoading = false;
        });

        // Auto-center map to show all markers with delay
        if (markers.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              _centerMapOnMarkers();
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show user-friendly error message
        String errorMessage = 'Error loading companies';
        if (e is TimeoutException) {
          errorMessage = 'Network timeout. Please check your connection.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your connection.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
          return Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/image10.jpg'),
                fit: BoxFit.cover,
                opacity: 0.1,
              ),
            ),
            child: SingleChildScrollView(
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
            ),
          );
        },
      ),
    ); // <-- This was the missing closing parenthesis
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

      // Show pickup assignment dialog
      final result = await _showPickupAssignmentDialog(companyData);
      if (result == null) return; // User cancelled

      // Close bottom sheet after successful assignment
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error assigning pickup: $e')));
    }
  }

  Future<Map<String, dynamic>?> _showPickupAssignmentDialog(
    Map<String, dynamic> companyData,
  ) async {
    String selectedWasteType = 'General';
    String userAddress = '';
    GeoPoint? userLocation;
    bool isLoading = false;
    bool useManualLocation = false;
    final TextEditingController latitudeController = TextEditingController();
    final TextEditingController longitudeController = TextEditingController();

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.assignment, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text('Assign Pickup'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Company: ${companyData['companyName']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Address Input
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Your Address',
                        hintText: 'Enter your pickup address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      onChanged: (value) => userAddress = value,
                    ),
                    const SizedBox(height: 16),

                    // Waste Type Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedWasteType,
                      decoration: const InputDecoration(
                        labelText: 'Waste Type',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.recycling),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      isExpanded: true,
                      items:
                          [
                            'General',
                            'Scrap',
                            'Plastic',
                            'Bio-degradable',
                            'All',
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedWasteType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Location Section
                    Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Location Method Toggle
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                useManualLocation = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !useManualLocation
                                    ? AppColors.primary
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.my_location,
                                    color: !useManualLocation
                                        ? Colors.white
                                        : Colors.grey[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Current',
                                    style: TextStyle(
                                      color: !useManualLocation
                                          ? Colors.white
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                useManualLocation = true;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: useManualLocation
                                    ? AppColors.primary
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.edit_location,
                                    color: useManualLocation
                                        ? Colors.white
                                        : Colors.grey[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Manual',
                                    style: TextStyle(
                                      color: useManualLocation
                                          ? Colors.white
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Location Input Based on Selection
                    if (!useManualLocation) ...[
                      // Automatic Location Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  setState(() {
                                    isLoading = true;
                                  });
                                  try {
                                    // Get current location
                                    Position position =
                                        await Geolocator.getCurrentPosition(
                                          desiredAccuracy:
                                              LocationAccuracy.high,
                                        );
                                    setState(() {
                                      userLocation = GeoPoint(
                                        position.latitude,
                                        position.longitude,
                                      );
                                      isLoading = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Location captured successfully!',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    setState(() {
                                      isLoading = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error getting location: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                          icon: isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location),
                          label: Text(
                            isLoading
                                ? 'Getting Location...'
                                : 'Capture Current Location',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ] else ...[
                      // Manual Location Input
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: latitudeController,
                              decoration: const InputDecoration(
                                labelText: 'Latitude',
                                hintText: 'e.g., 0.304833',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.gps_fixed),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  try {
                                    final lat = double.parse(value);
                                    final lng =
                                        longitudeController.text.isNotEmpty
                                        ? double.parse(longitudeController.text)
                                        : 0.0;
                                    userLocation = GeoPoint(lat, lng);
                                  } catch (e) {
                                    userLocation = null;
                                  }
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: longitudeController,
                              decoration: const InputDecoration(
                                labelText: 'Longitude',
                                hintText: 'e.g., 32.554851',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.gps_fixed),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  try {
                                    final lng = double.parse(value);
                                    final lat =
                                        latitudeController.text.isNotEmpty
                                        ? double.parse(latitudeController.text)
                                        : 0.0;
                                    userLocation = GeoPoint(lat, lng);
                                  } catch (e) {
                                    userLocation = null;
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter coordinates manually (e.g., 0.304833, 32.554851 for Kampala)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (userAddress.isEmpty || userLocation == null)
                      ? null
                      : () async {
                          // Show loading state
                          setState(() {
                            isLoading = true;
                          });

                          try {
                            // Send pickup order to Firestore
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              // Create pickup assignment document
                              final pickupData = {
                                'userId': user.uid,
                                'companyId': companyData['id'],
                                'companyName': companyData['companyName'],
                                'userEmail': user.email,
                                'userName': user.displayName ?? 'Unknown User',
                                'status': 'assigned',
                                'assignedAt': FieldValue.serverTimestamp(),
                                'wasteType': selectedWasteType,
                                'userLocation': userLocation,
                                'userAddress': userAddress,
                                'companyLocation': GeoPoint(
                                  companyData['latitude'],
                                  companyData['longitude'],
                                ),
                              };

                              // Save to pickup_assignments collection
                              await FirebaseFirestore.instance
                                  .collection('pickup_assignments')
                                  .add(pickupData);

                              // Also save to user's pickups subcollection
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .collection('pickups')
                                  .add({
                                    'companyId': companyData['id'],
                                    'companyName': companyData['companyName'],
                                    'status': 'pending',
                                    'createdAt': FieldValue.serverTimestamp(),
                                    'wasteType': selectedWasteType,
                                    'userLocation': userLocation,
                                    'userAddress': userAddress,
                                    'companyLocation': GeoPoint(
                                      companyData['latitude'],
                                      companyData['longitude'],
                                    ),
                                  });

                              // Update company's assigned pickups count
                              await FirebaseFirestore.instance
                                  .collection('companies')
                                  .doc(companyData['id'])
                                  .update({
                                    'assignedPickups': FieldValue.increment(1),
                                  });
                            }

                            // Close dialog and show success message
                            Navigator.of(context).pop({
                              'location': userLocation,
                              'wasteType': selectedWasteType,
                              'address': userAddress,
                            });

                            // Navigate to home page
                            Navigator.pushReplacementNamed(context, '/home');

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Pickup order saved successfull!',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            setState(() {
                              isLoading = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error sending pickup order: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
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
            onPressed: _isLoading ? null : _loadCompanyMarkers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildGoogleMap(),
          if (_isLoading) _buildLoadingOverlay(),
          Positioned(top: 16, right: 16, child: _buildMapLegend()),
        ],
      ),
    );
  }

  Widget _buildGoogleMap() {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(target: _currentPosition, zoom: 13),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      // Add performance optimizations
      liteModeEnabled: false,
      compassEnabled: false,
      mapType: MapType.normal,
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildMapLegend() {
    return Container(
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
              const Text('Waste Companies', style: TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.my_location, color: Colors.blue, size: 16),
              const SizedBox(width: 4),
              const Text('Your Location', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
