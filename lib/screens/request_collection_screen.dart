import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/location_picker_widget.dart';
import '../services/location_service.dart';
import 'package:collection/collection.dart';

class RequestCollectionScreen extends StatefulWidget {
  const RequestCollectionScreen({Key? key}) : super(key: key);

  @override
  State<RequestCollectionScreen> createState() => _RequestCollectionScreenState();
}

class _RequestCollectionScreenState extends State<RequestCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _urgency = 'Normal';
  final TextEditingController _streetController = TextEditingController();

  List<DocumentSnapshot> _companies = [];
  String? _selectedCompanyId;
  
  // Location-related variables
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  Future<void> _fetchCompanies() async {
    // Only fetch companies that have registered with location, are active, and approved
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('userType', isEqualTo: 'Company')
        .where('latitude', isNotEqualTo: null)
        .where('longitude', isNotEqualTo: null)
        .where('isApproved', isEqualTo: true) // Only approved companies
        .get();

    // Filter companies that have complete registration
    final validCompanies = snapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['name'] != null &&
             data['name'].toString().trim().isNotEmpty &&
             data['latitude'] != null &&
             data['longitude'] != null;
    }).toList();

    setState(() {
      _companies = validCompanies;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _openLocationPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerWidget(
          initialLocation: _selectedLocation,
          initialAddress: _selectedAddress,
          onLocationSelected: (location, address) {
            setState(() {
              _selectedLocation = location;
              _selectedAddress = address;
              _streetController.text = address;
            });
          },
        ),
      ),
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _selectedTime != null &&
        _selectedCompanyId != null &&
        _selectedLocation != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final dateStr =
          "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
      final timeStr = _selectedTime!.format(context);

      try {
        await FirebaseFirestore.instance.collection('requests').add({
          'userId': user.uid,
          'name': user.displayName ?? user.email ?? 'Client',
          'address': _selectedAddress.isNotEmpty ? _selectedAddress : _streetController.text.trim(),
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
          'urgency': _urgency,
          'date': dateStr,
          'time': timeStr,
          'status': 'Pending',
          'assignedCompanyId': _selectedCompanyId,
          'submittedAt': FieldValue.serverTimestamp(),
          'clientEmail': user.email,
        });

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Request Submitted'),
            content: const Text('Your waste collection request has been submitted!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );

        setState(() {
          _selectedDate = null;
          _selectedTime = null;
          _urgency = 'Normal';
          _streetController.clear();
          _selectedCompanyId = null;
          _selectedLocation = null;
          _selectedAddress = '';
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit request: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select date, time, location, and company.')),
      );
    }
  }

  Widget _buildSelectedCompanyInfo() {
    final selected = _companies.firstWhereOrNull((doc) => doc.id == _selectedCompanyId);
    if (selected == null) {
      return Text('No company selected.');
    }
    final data = selected.data() as Map<String, dynamic>;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Company: ${data['name'] ?? 'Unknown'}', style: TextStyle(fontWeight: FontWeight.bold)),
        if (data['email'] != null) Text('Email: ${data['email']}'),
        if (data['phone'] != null) Text('Phone: ${data['phone']}'),
        if (data['serviceRadius'] != null) Text('Service Radius: ${(data['serviceRadius'] / 1000).toStringAsFixed(1)} km'),
        if (data['address'] != null) Text('Address: ${data['address']}'),
        if (data['isApproved'] == true)
          Text('Status: Approved', style: TextStyle(color: Colors.green)),
        if (data['isApproved'] == false)
          Text('Status: Not Approved', style: TextStyle(color: Colors.red)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Waste Collection'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    _selectedDate == null
                        ? 'Select Day'
                        : "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}",
                  ),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(_selectedTime == null ? 'Select Time' : _selectedTime!.format(context)),
                  onTap: _pickTime,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _urgency,
                  items: const [
                    DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'Urgent', child: Text('Urgent')),
                  ],
                  onChanged: (value) => setState(() => _urgency = value!),
                  decoration: const InputDecoration(
                    labelText: 'Urgency',
                    prefixIcon: Icon(Icons.priority_high),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Location Picker Button
                Container(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openLocationPicker,
                    icon: Icon(Icons.location_on),
                    label: Text(
                      _selectedAddress.isEmpty
                        ? 'Select Location on Map'
                        : _selectedAddress,
                      style: TextStyle(
                        color: _selectedAddress.isEmpty ? Colors.grey[600] : Colors.black,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      alignment: Alignment.centerLeft,
                      side: BorderSide(
                        color: _selectedLocation == null ? Colors.red : Colors.grey,
                      ),
                    ),
                  ),
                ),
                
                if (_selectedLocation != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Location selected: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              color: Colors.green[800],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 12),

                // Company dropdown with enhanced information
                _companies.isNotEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedCompanyId,
                            items: _companies.map((companyDoc) {
                              final data = companyDoc.data() as Map<String, dynamic>;
                              final name = data['name'] ?? 'Unnamed Company';
                              final serviceRadius = (data['serviceRadius'] ?? 5000) / 1000; // Convert to km
                              
                              // Calculate distance if user location is available
                              String distanceInfo = '';
                              if (_selectedLocation != null) {
                                final companyLat = data['latitude'] as double?;
                                final companyLng = data['longitude'] as double?;
                                if (companyLat != null && companyLng != null) {
                                  final companyLocation = LatLng(companyLat, companyLng);
                                  final distance = _locationService.calculateDistance(
                                    _selectedLocation!,
                                    companyLocation,
                                  );
                                  final distanceKm = distance / 1000;
                                  distanceInfo = ' • ${distanceKm.toStringAsFixed(1)}km away';
                                  
                                  // Check if within service area
                                  if (distance > (data['serviceRadius'] ?? 5000)) {
                                    distanceInfo += ' (Outside service area)';
                                  }
                                }
                              }
                              
                              return DropdownMenuItem<String>(
                                value: companyDoc.id,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Service area: ${serviceRadius.toStringAsFixed(1)}km radius$distanceInfo',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => _selectedCompanyId = value),
                            decoration: const InputDecoration(
                              labelText: 'Choose Waste Collection Company',
                              prefixIcon: Icon(Icons.business),
                              border: OutlineInputBorder(),
                              helperText: 'Select a registered company near your location',
                            ),
                            validator: (value) =>
                                value == null ? 'Please choose a waste collection company' : null,
                            isExpanded: true,
                            itemHeight: 70, // Increased height for two-line items
                          ),
                          
                          // Show selected company details
                          if (_selectedCompanyId != null) ...[
                            SizedBox(height: 12),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: _buildSelectedCompanyInfo(),
                            ),
                          ],
                        ],
                      )
                    : Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.warning, color: Colors.orange[700], size: 32),
                            SizedBox(height: 8),
                            Text(
                              'No registered companies available',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[800],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Companies need to register and set up their location to appear here.',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Submit Request'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
