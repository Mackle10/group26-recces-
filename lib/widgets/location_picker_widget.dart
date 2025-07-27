import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../services/location_service.dart';
import '../services/geocoding_service.dart';
import '../services/map_service.dart';

class LocationPickerWidget extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng, String) onLocationSelected;
  final String? initialAddress;

  const LocationPickerWidget({
    Key? key,
    this.initialLocation,
    required this.onLocationSelected,
    this.initialAddress,
  }) : super(key: key);

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final LocationService _locationService = LocationService();
  final GeocodingService _geocodingService = GeocodingService();
  final MapService _mapService = MapService();

  LatLng? _selectedLocation;
  String _selectedAddress = '';
  bool _isLoading = false;
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    if (widget.initialAddress != null) {
      _searchController.text = widget.initialAddress!;
    }
  }

  void _initializeLocation() async {
    LatLng initialLocation;
    
    if (widget.initialLocation != null) {
      initialLocation = widget.initialLocation!;
    } else {
      // Try to get current location
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        initialLocation = _locationService.positionToLatLng(position);
      } else {
        // Fallback to Kampala
        initialLocation = _locationService.getDefaultLocation();
      }
    }

    setState(() {
      _selectedLocation = initialLocation;
      _updateMarker(initialLocation);
    });

    // Get address for the initial location
    _getAddressFromLocation(initialLocation);
  }

  void _updateMarker(LatLng location) {
    setState(() {
      _markers = [
        _mapService.createCustomMarker(
          location,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.location_on,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ];
    });
  }

  void _onMapTap(TapPosition tapPosition, LatLng location) {
    setState(() {
      _selectedLocation = location;
      _updateMarker(location);
    });
    _getAddressFromLocation(location);
  }

  void _getAddressFromLocation(LatLng location) async {
    setState(() => _isLoading = true);
    
    try {
      final address = await _geocodingService.getAddressFromCoordinates(location);
      setState(() {
        _selectedAddress = address ?? 'Unknown location';
        _searchController.text = _selectedAddress;
      });
    } catch (e) {
      setState(() {
        _selectedAddress = 'Unable to get address';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _getCurrentLocation() async {
    setState(() => _isLoading = true);
    
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        final location = _locationService.positionToLatLng(position);
        
        _mapController.move(location, 15.0);
        setState(() {
          _selectedLocation = location;
          _updateMarker(location);
        });
        _getAddressFromLocation(location);
      } else {
        _showErrorSnackBar('Unable to get current location');
      }
    } catch (e) {
      _showErrorSnackBar('Error getting location: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<List<PlaceResult>> _searchPlaces(String query) async {
    if (query.length < 3) return [];
    
    try {
      return await _geocodingService.searchInUganda(query);
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }

  void _selectPlace(PlaceResult place) {
    final location = place.coordinates;
    
    _mapController.move(location, 15.0);
    setState(() {
      _selectedLocation = location;
      _selectedAddress = place.shortAddress;
      _searchController.text = _selectedAddress;
      _updateMarker(location);
    });
  }

  void _confirmSelection() {
    if (_selectedLocation != null) {
      widget.onLocationSelected(_selectedLocation!, _selectedAddress);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Location'),
        actions: [
          if (_selectedLocation != null)
            TextButton(
              onPressed: _confirmSelection,
              child: Text(
                'CONFIRM',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: EdgeInsets.all(16),
            child: TypeAheadField<PlaceResult>(
              textFieldConfiguration: TextFieldConfiguration(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for a location...',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: _isLoading
                      ? Container(
                          width: 20,
                          height: 20,
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: Icon(Icons.my_location),
                          onPressed: _getCurrentLocation,
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              suggestionsCallback: _searchPlaces,
              itemBuilder: (context, PlaceResult suggestion) {
                return ListTile(
                  leading: Icon(Icons.location_on),
                  title: Text(suggestion.shortAddress),
                  subtitle: Text(suggestion.displayName),
                );
              },
              onSuggestionSelected: _selectPlace,
              noItemsFoundBuilder: (context) => Padding(
                padding: EdgeInsets.all(16),
                child: Text('No locations found'),
              ),
            ),
          ),
          
          // Map
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: _mapService.getDefaultMapOptions(
                center: _selectedLocation ?? _locationService.getDefaultLocation(),
                zoom: 13.0,
                onTap: _onMapTap,
              ),
              children: [
                _mapService.getOpenStreetMapTileLayer(),
                MarkerLayer(markers: _markers),
              ],
            ),
          ),
          
          // Selected address display
          if (_selectedAddress.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Location:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _selectedAddress,
                    style: TextStyle(fontSize: 16),
                  ),
                  if (_selectedLocation != null) ...[
                    SizedBox(height: 4),
                    Text(
                      'Coordinates: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "current_location",
            onPressed: _getCurrentLocation,
            child: Icon(Icons.my_location),
            backgroundColor: Colors.blue,
            mini: true,
          ),
          SizedBox(height: 8),
          if (_selectedLocation != null)
            FloatingActionButton(
              heroTag: "confirm_location",
              onPressed: _confirmSelection,
              child: Icon(Icons.check),
              backgroundColor: Colors.green,
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}