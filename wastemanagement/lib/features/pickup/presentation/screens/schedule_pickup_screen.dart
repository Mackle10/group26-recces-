import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wastemanagement/core/constants/app_colors.dart';
import 'package:wastemanagement/data/models/recycle_model.dart';
import 'package:wastemanagement/data/datasources/remote/firebase_datasource.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SchedulePickupScreen extends StatefulWidget {
  final String? streetName;
  final String? plotNumber;
  const SchedulePickupScreen({super.key, this.streetName, this.plotNumber});

  @override
  State<SchedulePickupScreen> createState() => _SchedulePickupScreenState();
}

class _SchedulePickupScreenState extends State<SchedulePickupScreen> {
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(-1.2921, 36.8219);
  String? _selectedWasteType;
  DateTime? _selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Pickup'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          if (widget.streetName != null || widget.plotNumber != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.streetName != null)
                    Text('Street Name: ${widget.streetName!}'),
                  if (widget.plotNumber != null)
                    Text('Plot Number: ${widget.plotNumber!}'),
                ],
              ),
            ),
          SizedBox(
            height: 250,
            child: GoogleMap(
              onMapCreated: (controller) => mapController = controller,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('pickup_location'),
                  position: _center,
                ),
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedWasteType,
                    decoration: InputDecoration(
                      labelText: 'Waste Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: ['General', 'Recyclable', 'Hazardous']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedWasteType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightGreen2,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => _selectDate(context),
                    child: Text(
                      _selectedDate == null
                          ? 'Select Pickup Date'
                          : 'Selected: ${_selectedDate!.toLocal()}'.split(' ')[0],
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _selectedDate == null || _selectedWasteType == null
                        ? null
                        : () async {
                            // Handle pickup scheduling
                            await (FirebaseDataSourceImpl()).postRecyclable(RecyclableModel(
                              userId: FirebaseAuth.instance.currentUser!.uid,
                              type: _selectedWasteType!,
                              quantity: 1,
                              price: 100,
                              status: 'pending',
                              // createdAt: FieldValue.serverTimestamp(),
                              createdAt: DateTime.now(),
                              purchasedAt: _selectedDate,
                              purchasedBy: FirebaseAuth.instance.currentUser!.uid,
                            ));
                            Navigator.pop(context);
                          },
                    child: const Text('Confirm Pickup'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}