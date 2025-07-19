// O11 import 'package:flutter/material.dart';
// O11 import 'package:google_maps_flutter/google_maps_flutter.dart';
// O11 import 'package:wastemanagement/core/constants/app_colors.dart';

// O11 class HomeScreen extends StatefulWidget {
// O11   const HomeScreen({super.key});

// O11   @override
// O11   State<HomeScreen> createState() => _HomeScreenState();
// O11 }

// O11 class _HomeScreenState extends State<HomeScreen> {
// O11   late GoogleMapController mapController;
// O11   final LatLng _center = const LatLng(-1.2921, 36.8219); // Nairobi coordinates

// O11   void _onMapCreated(GoogleMapController controller) {
// O11     mapController = controller;
// O11   }

// O11   @override
// O11   Widget build(BuildContext context) {
// O11     return Scaffold(
// O11       appBar: AppBar(
// O11         title: const Text('Waste Collection'),
// O11         backgroundColor: AppColors.primary,
// O11       ),
// O11       body: Column(
// O11         children: [
// O11           Expanded(
// O11             child: GoogleMap(
// O11               onMapCreated: _onMapCreated,
// O11               initialCameraPosition: CameraPosition(
// O11                 target: _center,
// O11                 zoom: 11.0,
// O11               ),
// O11               markers: {
// O11                 Marker(
// O11                   markerId: const MarkerId('user_location'),
// O11                   position: _center,
// O11                   infoWindow: const InfoWindow(title: 'Your Location'),
// O11                 ),
// O11               },
// O11             ),
// O11           ),
// O11           Container(
// O11             padding: const EdgeInsets.all(16),
// O11             color: AppColors.lightGreen1,
// O11             child: Row(
// O11               children: [
// O11                 Expanded(
// O11                   child: ElevatedButton(
// O11                     style: ElevatedButton.styleFrom(
// O11                       backgroundColor: AppColors.secondary,
// O11                       padding: const EdgeInsets.symmetric(vertical: 16),
// O11                     ),
// O11                     onPressed: () {
// O11                       Navigator.pushNamed(context, AppRoutes.schedulePickup);
// O11                     },
// O11                     child: const Text('Schedule Pickup'),
// O11                   ),
// O11                 ),
// O11               ],
// O11             ),
// O11           ),
// O11         ],
// O11       ),
// O11     );
// O11   }
// O11 }

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  final LatLng _initialPosition = const LatLng(37.7749, -122.4194); // San Francisco

  final Set<Marker> _markers = {};

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected-location'),
          position: position,
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected: ${position.latitude}, ${position.longitude}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 12,
        ),
        markers: _markers,
        onTap: _onMapTap,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: false,
      ),
    );
  }
}
