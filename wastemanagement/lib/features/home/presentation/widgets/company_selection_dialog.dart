import 'package:flutter/material.dart';
import 'package:wastemanagement/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class CompanySelectionDialog extends StatefulWidget {
  final bool isRegistrationFlow;

  const CompanySelectionDialog({super.key, this.isRegistrationFlow = false});

  @override
  State<CompanySelectionDialog> createState() => _CompanySelectionDialogState();
}

class _CompanySelectionDialogState extends State<CompanySelectionDialog> {
  String? _selectedWasteType;
  String? _companyName;
  String? _phoneNumber;
  String? _address;
  bool _isLoading = false;
  Position? _currentPosition;

  // Manual coordinate inputs
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  bool _useManualCoordinates = false;

  final List<String> _wasteTypes = [
    'Scrap',
    'Plastic',
    'Bio-degradable',
    'All',
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied'),
          ),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        // Pre-fill manual coordinates with current location
        _latitudeController.text = position.latitude.toStringAsFixed(6);
        _longitudeController.text = position.longitude.toStringAsFixed(6);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
    }
  }

  Position? _getSelectedPosition() {
    if (_useManualCoordinates) {
      try {
        final lat = double.parse(_latitudeController.text);
        final lng = double.parse(_longitudeController.text);
        return Position(
          latitude: lat,
          longitude: lng,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      } catch (e) {
        return null;
      }
    } else {
      return _currentPosition;
    }
  }

  Future<void> _saveCompanyData() async {
    if (_selectedWasteType == null ||
        _companyName == null ||
        _companyName!.isEmpty ||
        _phoneNumber == null ||
        _phoneNumber!.isEmpty ||
        _address == null ||
        _address!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final position = _getSelectedPosition();
    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide valid coordinates')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.isRegistrationFlow) {
        // For registration flow, just return the company data
        // The registration process will handle user creation
        final companyData = {
          'companyName': _companyName,
          'phoneNumber': _phoneNumber,
          'address': _address,
          'wasteType': _selectedWasteType,
          'location': GeoPoint(position.latitude, position.longitude),
          'coordinates': {
            'latitude': position.latitude,
            'longitude': position.longitude,
          },
          'isAvailable': true,
        };

        setState(() {
          _isLoading = false;
        });

        Navigator.of(context).pop({
          'success': true,
          'companyData': companyData,
          'companyName': _companyName,
          'wasteType': _selectedWasteType,
          'location': position,
        });
      } else {
        // For post-registration flow, save to Firestore
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not authenticated')),
          );
          return;
        }

        // Save company data to Firestore
        await FirebaseFirestore.instance
            .collection('companies')
            .doc(user.uid)
            .set({
              'userId': user.uid,
              'companyName': _companyName,
              'phoneNumber': _phoneNumber,
              'address': _address,
              'wasteType': _selectedWasteType,
              'location': GeoPoint(position.latitude, position.longitude),
              'coordinates': {
                'latitude': position.latitude,
                'longitude': position.longitude,
              },
              'isAvailable': true,
              'createdAt': FieldValue.serverTimestamp(),
              'email': user.email,
            });

        // Update user role to company
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'role': 'company',
              'companyData': {
                'companyName': _companyName,
                'wasteType': _selectedWasteType,
                'address': _address,
              },
            });

        setState(() {
          _isLoading = false;
        });

        Navigator.of(context).pop({
          'success': true,
          'companyName': _companyName,
          'wasteType': _selectedWasteType,
          'location': position,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company profile created successfully!'),
            backgroundColor: AppColors.lightGreen1,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving data: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.business,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Company Profile Setup',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company Name
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Company Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.business),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (value) => _companyName = value,
                    ),
                    const SizedBox(height: 12),

                    // Phone Number
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.phone),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (value) => _phoneNumber = value,
                    ),
                    const SizedBox(height: 12),

                    // Address
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Company Address',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.location_on),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      maxLines: 2,
                      onChanged: (value) => _address = value,
                    ),
                    const SizedBox(height: 12),

                    // Waste Type Selection
                    DropdownButtonFormField<String>(
                      value: _selectedWasteType,
                      decoration: InputDecoration(
                        labelText: 'Waste Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.recycling),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: _wasteTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedWasteType = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Location Selection
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Company Location',
                          style: TextStyle(
                            fontSize: 14,
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
                                    _useManualCoordinates = false;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !_useManualCoordinates
                                        ? AppColors.primary.withOpacity(0.1)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: !_useManualCoordinates
                                          ? AppColors.primary
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.my_location,
                                        size: 16,
                                        color: !_useManualCoordinates
                                            ? AppColors.primary
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Current',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: !_useManualCoordinates
                                              ? AppColors.primary
                                              : Colors.grey,
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
                                    _useManualCoordinates = true;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _useManualCoordinates
                                        ? AppColors.primary.withOpacity(0.1)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: _useManualCoordinates
                                          ? AppColors.primary
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.edit_location,
                                        size: 16,
                                        color: _useManualCoordinates
                                            ? AppColors.primary
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Manual',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _useManualCoordinates
                                              ? AppColors.primary
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Manual Coordinates Input
                        if (_useManualCoordinates) ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _latitudeController,
                                  decoration: InputDecoration(
                                    labelText: 'Latitude',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  keyboardType: TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _longitudeController,
                                  decoration: InputDecoration(
                                    labelText: 'Longitude',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  keyboardType: TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          // Current Location Status
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _currentPosition != null
                                  ? AppColors.lightGreen1.withOpacity(0.2)
                                  : AppColors.secondary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _currentPosition != null
                                    ? AppColors.lightGreen1
                                    : AppColors.secondary,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _currentPosition != null
                                      ? Icons.location_on
                                      : Icons.location_off,
                                  color: _currentPosition != null
                                      ? AppColors.lightGreen1
                                      : AppColors.secondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _currentPosition != null
                                        ? 'Location: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}'
                                        : 'Getting location...',
                                    style: TextStyle(
                                      color: _currentPosition != null
                                          ? AppColors.lightGreen1
                                          : AppColors.secondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveCompanyData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.white,
                                ),
                              ),
                            )
                          : const Text('Save Profile'),
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
}
