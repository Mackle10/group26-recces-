 import 'package:google_maps_flutter/google_maps_flutter.dart';
 import 'package:location/location.dart';

 class LocationHelper {
   static Future<LatLng> getCurrentLocation() async {
     final location = Location();
     bool serviceEnabled;
     PermissionStatus permissionGranted;

     serviceEnabled = await location.serviceEnabled();
     if (!serviceEnabled) {
       serviceEnabled = await location.requestService();
       if (!serviceEnabled) {
         throw Exception('Location services are disabled.');
       }
     }

     permissionGranted = await location.hasPermission();
     if (permissionGranted == PermissionStatus.denied) {
       permissionGranted = await location.requestPermission();
       if (permissionGranted != PermissionStatus.granted) {
         throw Exception('Location permissions are denied');
       }
     }

     final locationData = await location.getLocation();
     return LatLng(locationData.latitude!, locationData.longitude!);
   }

   static List<LatLng> decodePolyline(String encoded) {
     List<LatLng> poly = [];
     int index = 0, len = encoded.length;
     int lat = 0, lng = 0;

     while (index < len) {
       int b, shift = 0, result = 0;
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

       LatLng p = LatLng(lat / 1E5, lng / 1E5);
       poly.add(p);
     }
     return poly;
   }
 }