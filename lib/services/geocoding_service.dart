import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingService {
  static final GeocodingService _instance = GeocodingService._internal();
  factory GeocodingService() => _instance;
  GeocodingService._internal();

  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  static const String _userAgent = 'WasteManagementApp/1.0';

  /// Search for places by query string
  Future<List<PlaceResult>> searchPlaces(String query, {
    String? countryCode = 'UG', // Default to Uganda
    int limit = 5,
  }) async {
    try {
      final uri = Uri.parse('$_nominatimBaseUrl/search').replace(
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': '1',
          'limit': limit.toString(),
          if (countryCode != null) 'countrycodes': countryCode,
          'accept-language': 'en',
        },
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': _userAgent},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => PlaceResult.fromJson(item)).toList();
      } else {
        throw Exception('Failed to search places: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }

  /// Reverse geocoding - get address from coordinates
  Future<PlaceResult?> reverseGeocode(LatLng coordinates) async {
    try {
      final uri = Uri.parse('$_nominatimBaseUrl/reverse').replace(
        queryParameters: {
          'lat': coordinates.latitude.toString(),
          'lon': coordinates.longitude.toString(),
          'format': 'json',
          'addressdetails': '1',
          'accept-language': 'en',
        },
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': _userAgent},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return PlaceResult.fromJson(data);
      } else {
        throw Exception('Failed to reverse geocode: ${response.statusCode}');
      }
    } catch (e) {
      print('Error reverse geocoding: $e');
      return null;
    }
  }

  /// Search for places specifically in Uganda
  Future<List<PlaceResult>> searchInUganda(String query) async {
    return await searchPlaces(query, countryCode: 'UG');
  }

  /// Search for places in Kampala specifically
  Future<List<PlaceResult>> searchInKampala(String query) async {
    return await searchPlaces('$query, Kampala, Uganda', countryCode: 'UG');
  }

  /// Get coordinates for a specific address
  Future<LatLng?> getCoordinatesFromAddress(String address) async {
    final results = await searchPlaces(address);
    if (results.isNotEmpty) {
      return results.first.coordinates;
    }
    return null;
  }

  /// Get formatted address from coordinates
  Future<String?> getAddressFromCoordinates(LatLng coordinates) async {
    final result = await reverseGeocode(coordinates);
    return result?.displayName;
  }
}

class PlaceResult {
  final String displayName;
  final LatLng coordinates;
  final String? houseNumber;
  final String? road;
  final String? suburb;
  final String? city;
  final String? county;
  final String? state;
  final String? country;
  final String? postcode;
  final String placeId;
  final String type;

  PlaceResult({
    required this.displayName,
    required this.coordinates,
    this.houseNumber,
    this.road,
    this.suburb,
    this.city,
    this.county,
    this.state,
    this.country,
    this.postcode,
    required this.placeId,
    required this.type,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>? ?? {};
    
    return PlaceResult(
      displayName: json['display_name'] ?? '',
      coordinates: LatLng(
        double.parse(json['lat'].toString()),
        double.parse(json['lon'].toString()),
      ),
      houseNumber: address['house_number'],
      road: address['road'],
      suburb: address['suburb'] ?? address['neighbourhood'],
      city: address['city'] ?? address['town'] ?? address['village'],
      county: address['county'],
      state: address['state'],
      country: address['country'],
      postcode: address['postcode'],
      placeId: json['place_id']?.toString() ?? '',
      type: json['type'] ?? json['class'] ?? 'unknown',
    );
  }

  /// Get a short formatted address
  String get shortAddress {
    List<String> parts = [];
    
    if (houseNumber != null && road != null) {
      parts.add('$houseNumber $road');
    } else if (road != null) {
      parts.add(road!);
    }
    
    if (suburb != null) parts.add(suburb!);
    if (city != null) parts.add(city!);
    
    return parts.join(', ');
  }

  /// Get a medium formatted address
  String get mediumAddress {
    List<String> parts = [];
    
    if (houseNumber != null && road != null) {
      parts.add('$houseNumber $road');
    } else if (road != null) {
      parts.add(road!);
    }
    
    if (suburb != null) parts.add(suburb!);
    if (city != null) parts.add(city!);
    if (county != null) parts.add(county!);
    
    return parts.join(', ');
  }

  /// Check if this is a valid address for waste collection
  bool get isValidForCollection {
    return road != null && (city != null || suburb != null);
  }

  @override
  String toString() => displayName;

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'latitude': coordinates.latitude,
      'longitude': coordinates.longitude,
      'houseNumber': houseNumber,
      'road': road,
      'suburb': suburb,
      'city': city,
      'county': county,
      'state': state,
      'country': country,
      'postcode': postcode,
      'placeId': placeId,
      'type': type,
    };
  }

  factory PlaceResult.fromMap(Map<String, dynamic> map) {
    return PlaceResult(
      displayName: map['displayName'] ?? '',
      coordinates: LatLng(map['latitude'] ?? 0.0, map['longitude'] ?? 0.0),
      houseNumber: map['houseNumber'],
      road: map['road'],
      suburb: map['suburb'],
      city: map['city'],
      county: map['county'],
      state: map['state'],
      country: map['country'],
      postcode: map['postcode'],
      placeId: map['placeId'] ?? '',
      type: map['type'] ?? 'unknown',
    );
  }
}