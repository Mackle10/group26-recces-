import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wastemanagement/core/constants/app_colors.dart';
import "dart:convert";
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

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
      ...(latlngs.map((latlng) {
        final lat = latlng[0];
        final lng = latlng[1];
        return Marker(
          markerId: MarkerId('recycle_${lat}_${lng}'),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(title: 'Recycle Point'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        );
      }).toList()),
    };

    _polylines = {
      // Polyline(
      //   polylineId: const PolylineId('route'),
      //   points: [_companyLocation, _customerLocation],
      //   color: AppColors.primary,
      //   width: 5,
      // ),
    };

    _generateRoutes();
  }

  void _generateRoutes() async {
    final currentLocation = await _getCurrentLocation();
    // Example of generating a route between two points
    final route = MapRoute(start: _companyLocation, end: _customerLocation);
    final polyline = await route.generatePolyline('route1');
    setState(() {
      _currentLocation = currentLocation;
      _polylines.add(polyline);
    });
  }

  Future<LatLng> _getCurrentLocation() async {
     Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    double lat = position.latitude;
    double long = position.longitude;
    LatLng location = LatLng(lat, long);

    return location;
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
                zoom: 15,
              ),
              markers: { ..._markers,
                ...(_currentLocation == null ? [] : [Marker(
                  markerId: const MarkerId('current_location'),
                  position: _currentLocation as LatLng,
                  infoWindow: const InfoWindow(title: 'Current Location'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                )]),
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
    final String destination ="${end.latitude},${end.longitude}";

    final String mainApi = "https://maps.googleapis.com/maps/api/directions/json?origin=${origin}&destination=${destination}&key=${apiKey}";
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