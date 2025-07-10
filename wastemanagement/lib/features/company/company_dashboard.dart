import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wastemanagement/core/constants/app_colors.dart';

class CompanyDashboard extends StatefulWidget {
  const CompanyDashboard({super.key});

  @override
  State<CompanyDashboard> createState() => _CompanyDashboardState();
}

class _CompanyDashboardState extends State<CompanyDashboard> {
  late GoogleMapController mapController;
  final LatLng _companyLocation = const LatLng(-1.2921, 36.8219);
  final LatLng _customerLocation = const LatLng(-1.3000, 36.8300);
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _markers = {
      Marker(
        markerId: const MarkerId('company'),
        position: _companyLocation,
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('customer'),
        position: _customerLocation,
        infoWindow: const InfoWindow(title: 'Customer Pickup'),
      ),
    };

    _polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [_companyLocation, _customerLocation],
        color: AppColors.primary,
        width: 5,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Dashboard'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: (controller) => mapController = controller,
              initialCameraPosition: CameraPosition(
                target: _companyLocation,
                zoom: 12,
              ),
              markers: _markers,
              polylines: _polylines,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.lightGreen1,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Customer Name'),
                  subtitle: const Text('123 Main St, Nairobi'),
                  trailing: Chip(
                    label: const Text('Recyclable'),
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
                        onPressed: () {},
                        child: const Text('Start Pickup'),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}