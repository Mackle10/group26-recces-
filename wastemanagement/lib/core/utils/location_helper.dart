// O11 import 'package:google_maps_flutter/google_maps_flutter.dart';
// O11 import 'package:location/location.dart';

// O11 class LocationHelper {
// O11   static Future<LatLng> getCurrentLocation() async {
// O11     final location = Location();
// O11     bool serviceEnabled;
// O11     PermissionStatus permissionGranted;

// O11     serviceEnabled = await location.serviceEnabled();
// O11     if (!serviceEnabled) {
// O11       serviceEnabled = await location.requestService();
// O11       if (!serviceEnabled) {
// O11         throw Exception('Location services are disabled.');
// O11       }
// O11     }

// O11     permissionGranted = await location.hasPermission();
// O11     if (permissionGranted == PermissionStatus.denied) {
// O11       permissionGranted = await location.requestPermission();
// O11       if (permissionGranted != PermissionStatus.granted) {
// O11         throw Exception('Location permissions are denied');
// O11       }
// O11     }

// O11     final locationData = await location.getLocation();
// O11     return LatLng(locationData.latitude!, locationData.longitude!);
// O11   }

// O11   static List<LatLng> decodePolyline(String encoded) {
// O11     List<LatLng> poly = [];
// O11     int index = 0, len = encoded.length;
// O11     int lat = 0, lng = 0;

// O11     while (index < len) {
// O11       int b, shift = 0, result = 0;
// O11       do {
// O11         b = encoded.codeUnitAt(index++) - 63;
// O11         result |= (b & 0x1f) << shift;
// O11         shift += 5;
// O11       } while (b >= 0x20);
// O11       int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
// O11       lat += dlat;

// O11       shift = 0;
// O11       result = 0;
// O11       do {
// O11         b = encoded.codeUnitAt(index++) - 63;
// O11         result |= (b & 0x1f) << shift;
// O11         shift += 5;
// O11       } while (b >= 0x20);
// O11       int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
// O11       lng += dlng;

// O11       LatLng p = LatLng(lat / 1E5, lng / 1E5);
// O11       poly.add(p);
// O11     }
// O11     return poly;
// O11   }
// O11 }