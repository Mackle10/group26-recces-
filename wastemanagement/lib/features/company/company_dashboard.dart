import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wastemanagement/core/constants/app_colors.dart';
import 'package:wastemanagement/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:wastemanagement/routes/app_routes.dart';
import "dart:convert";
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompanyDashboard extends StatefulWidget {
  const CompanyDashboard({super.key});

  @override
  State<CompanyDashboard> createState() => _CompanyDashboardState();
}

class _CompanyDashboardState extends State<CompanyDashboard> {
  late GoogleMapController mapController;
  final latlngs = [
    [0.334782, 32.568602],
    [0.335004, 32.564514],
    [0.331328, 32.567525],
    [0.333673, 32.571581],
  ];

  LatLng? _currentLocation;
  final LatLng _companyLocation = const LatLng(0.333229, 32.568032);
  final LatLng _customerLocation = const LatLng(0.331229, 32.565032);
  Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  List<Map<String, dynamic>> _assignedPickups = [];
  bool _isLoadingRoutes = false;

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
    _loadAssignedPickups();
  }

  void _initializeMarkers() {
    _markers = {
      Marker(
        markerId: const MarkerId('company'),
        position: _companyLocation,
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      ...(latlngs.map((latlng) {
        final lat = latlng[0];
        final lng = latlng[1];
        return Marker(
          markerId: MarkerId('recycle_${lat}_$lng'),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(title: 'Recycle Point'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        );
      }).toList()),
    };
  }

  Future<void> _loadAssignedPickups() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final QuerySnapshot pickupSnapshot = await FirebaseFirestore.instance
          .collection('pickup_assignments')
          .where('companyId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'assigned')
          .get();

      final List<Map<String, dynamic>> pickups = [];
      for (var doc in pickupSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Get user details
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(data['userId'])
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          pickups.add({
            'id': doc.id,
            'userId': data['userId'],
            'userName': userData['name'] ?? 'Unknown User',
            'userAddress': userData['address'] ?? 'No Address',
            'userLocation': data['userLocation'],
            'wasteType': data['wasteType'] ?? 'General',
            'status': data['status'],
            'assignedAt': data['assignedAt'],
          });
        }
      }

      setState(() {
        _assignedPickups = pickups;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading assigned pickups: $e')),
      );
    }
  }

  Future<void> _generateOptimalRoutes() async {
    if (_assignedPickups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No assigned pickups found')),
      );
      return;
    }

    setState(() {
      _isLoadingRoutes = true;
    });

    try {
      // Clear existing polylines
      _polylines.clear();

      // Create markers for assigned pickups
      final Set<Marker> pickupMarkers = {};
      final List<LatLng> pickupLocations = [];

      for (int i = 0; i < _assignedPickups.length; i++) {
        final pickup = _assignedPickups[i];
        final location = pickup['userLocation'] as GeoPoint;
        final latLng = LatLng(location.latitude, location.longitude);

        pickupMarkers.add(
          Marker(
            markerId: MarkerId('pickup_${pickup['id']}'),
            position: latLng,
            infoWindow: InfoWindow(
              title: pickup['userName'],
              snippet: '${pickup['wasteType']} • ${pickup['userAddress']}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
        pickupLocations.add(latLng);
      }

      // Update markers
      setState(() {
        _markers = {..._markers, ...pickupMarkers};
      });

      // Generate route from company to all pickup locations
      if (pickupLocations.isNotEmpty) {
        await _generateRouteToPickups(pickupLocations);
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Generated route for ${_assignedPickups.length} pickups',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating routes: $e')));
    } finally {
      setState(() {
        _isLoadingRoutes = false;
      });
    }
  }

  Future<void> _generateRouteToPickups(List<LatLng> pickupLocations) async {
    // Simple route generation: company -> nearest pickup -> next nearest, etc.
    // In a real app, you'd use a more sophisticated algorithm like TSP

    List<LatLng> route = [_companyLocation];
    List<LatLng> remaining = List.from(pickupLocations);

    while (remaining.isNotEmpty) {
      // Find nearest pickup to current location
      LatLng current = route.last;
      int nearestIndex = 0;
      double minDistance = double.infinity;

      for (int i = 0; i < remaining.length; i++) {
        double distance = _calculateDistance(current, remaining[i]);
        if (distance < minDistance) {
          minDistance = distance;
          nearestIndex = i;
        }
      }

      route.add(remaining[nearestIndex]);
      remaining.removeAt(nearestIndex);
    }

    // Generate polyline for the route
    final polyline = Polyline(
      polylineId: const PolylineId('pickup_route'),
      points: route,
      color: AppColors.primary,
      width: 5,
    );

    setState(() {
      _polylines.add(polyline);
    });
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  Future<LatLng> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    double lat = position.latitude;
    double long = position.longitude;
    LatLng location = LatLng(lat, long);

    return location;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Company Dashboard'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                _showLogoutDialog(context);
              },
              tooltip: 'Logout',
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: GoogleMap(
                onMapCreated: (controller) => mapController = controller,
                initialCameraPosition: CameraPosition(
                  target: _companyLocation,
                  zoom: 15,
                ),
                markers: {
                  ..._markers,
                  ...(_currentLocation == null
                      ? []
                      : [
                          Marker(
                            markerId: const MarkerId('current_location'),
                            position: _currentLocation as LatLng,
                            infoWindow: const InfoWindow(
                              title: 'Current Location',
                            ),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueBlue,
                            ),
                          ),
                        ]),
                },
                polylines: _polylines,
                // polylines:
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.lightGreen1,
              child: Column(
                children: [
                  _assignedPickups.isEmpty
                      ? ListTile(
                          title: const Text('No Assigned Pickups'),
                          subtitle: const Text(
                            'No customers assigned for pickup',
                          ),
                          trailing: Chip(
                            label: const Text('0'),
                            backgroundColor: Colors.grey[300],
                          ),
                        )
                      : ListTile(
                          title: Text(
                            '${_assignedPickups.length} Assigned Pickups',
                          ),
                          subtitle: Text(
                            '${_assignedPickups.length} customers waiting for pickup',
                          ),
                          trailing: Chip(
                            label: Text('${_assignedPickups.length}'),
                            backgroundColor: AppColors.lightGreen2,
                          ),
                        ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _isLoadingRoutes
                              ? null
                              : _generateOptimalRoutes,
                          child: _isLoadingRoutes
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Start Pickup'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {},
                          child: const Text('Contact'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.recyclablesMarketplace,
                        );
                      },
                      icon: const Icon(Icons.recycling, color: Colors.white),
                      label: const Text(
                        'Recyclables Marketplace',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show logout confirmation dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Dispatch logout event
                context.read<AuthBloc>().add(LogoutRequested());
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

class MapRoute {
  final LatLng start;
  final LatLng end;
  late String apiKey;

  MapRoute({required this.start, required this.end}) {
    apiKey = dotenv.env['GOOGLEMAPS_KEY'] ?? "";
  }

  // Polyline toPolyline() {
  //   return Polyline(
  //     polylineId: PolylineId('route_${start.latitude}_${start.longitude}_${end.latitude}_${end.longitude}'),
  //     points: [start, end],
  //     color: AppColors.primary,
  //     width: 5,
  //   );
  // }

  Future<Polyline> generatePolyline(String id) async {
    final String origin = "${start.latitude},${start.longitude}";
    final String destination = "${end.latitude},${end.longitude}";

    final String mainApi =
        "https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$apiKey";
    final Uri uri = Uri.parse(mainApi);
    var response = await http.get(uri);

    Map data = json.decode(response.body);
    String encodedString = data['routes'][0]['overview_polyline']['points'];
    List<LatLng> points = _decodePoly(encodedString);

    // setState(() {
    //   _polylines.add(
    //     Polyline(
    //         polylineId: const PolylineId('route1'),
    //         visible: true,
    //         points: points,
    //         //width: 4,
    //         color: Colors.purple),
    //   );
    // });
    return Polyline(
      polylineId: PolylineId(id),
      visible: true,
      points: points,
      //width: 4,
      color: Colors.orange,
    );
  }

  List<LatLng> _decodePoly(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int shift = 0, result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      LatLng point = LatLng(lat / 1E5, lng / 1E5);
      points.add(point);
    }

    return points;
  }
}
