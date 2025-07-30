import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wastemanagement/core/constants/app_colors.dart';
import 'package:wastemanagement/data/models/pickup_history_model.dart';
import 'package:wastemanagement/core/services/history_service.dart';
import 'package:wastemanagement/core/services/notification_service.dart';
import 'package:wastemanagement/core/services/pickup_assignment_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SchedulePickupScreen extends StatefulWidget {
  final String? streetName;
  final String? plotNumber;
  const SchedulePickupScreen({super.key, this.streetName, this.plotNumber});

  @override
  State<SchedulePickupScreen> createState() => _SchedulePickupScreenState();
}

class _SchedulePickupScreenState extends State<SchedulePickupScreen> {
  int _selectedIndex = 0;
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(-1.2921, 36.8219);
  String? _selectedWasteType;
  DateTime? _selectedDate;
  final HistoryService _historyService = HistoryService();
  final NotificationService _notificationService = NotificationService();
  final PickupAssignmentService _assignmentService = PickupAssignmentService();
  bool _isLoading = false;

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.black.withOpacity(0.5),
      backgroundColor: AppColors.white,
      elevation: 8,
      showUnselectedLabels: true,
    );
  }

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
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    final bottomNavHeight = kBottomNavigationBarHeight;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final availableHeight =
        screenHeight - appBarHeight - bottomNavHeight - statusBarHeight;

    // Calculate map height based on available space
    final mapHeight = availableHeight * 0.4; // 40% of available space
    final formHeight = availableHeight * 0.6; // 60% of available space

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Pickup'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Location info (if provided)
          if (widget.streetName != null || widget.plotNumber != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.streetName != null)
                          Text(
                            widget.streetName!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        if (widget.plotNumber != null)
                          Text(
                            'Plot: ${widget.plotNumber!}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Map Section
          Container(
            height: mapHeight,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
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
          ),

          // Form Section
          Expanded(
            child: Container(
              height: formHeight,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Waste Type Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedWasteType,
                    decoration: InputDecoration(
                      labelText: 'Waste Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: ['General', 'Recyclable', 'Hazardous'].map((
                      String value,
                    ) {
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

                  const SizedBox(height: 12),

                  // Date Selection Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightGreen2,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        _selectedDate == null
                            ? 'Select Pickup Date'
                            : 'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _selectedDate == null ||
                          _selectedWasteType == null ||
                          _isLoading
                          ? null
                          : _schedulePickup,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Confirm Pickup',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Future<void> _schedulePickup() async {
    if (_selectedDate == null || _selectedWasteType == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create pickup history entry
      final pickup = PickupHistoryModel(
        id: '', // Will be set by Firestore
        userId: FirebaseAuth.instance.currentUser!.uid,
        wasteType: _selectedWasteType!,
        status: 'pending',
        scheduledDate: _selectedDate!,
        address: widget.streetName != null && widget.plotNumber != null
            ? '${widget.streetName}, Plot ${widget.plotNumber}'
            : null,
        latitude: _center.latitude,
        longitude: _center.longitude,
      );

      // Save to history
      String pickupId = await _historyService.createPickupHistory(pickup);

      // Auto-assign pickup to nearest company
      try {
        await _assignmentService.assignPickupToCompany(pickupId);
      } catch (e) {
        print('Failed to auto-assign pickup: $e');
        // Continue even if assignment fails - pickup will remain pending
      }

      // Schedule notification reminder (1 hour before pickup)
      DateTime reminderTime = _selectedDate!.subtract(const Duration(hours: 1));
      if (reminderTime.isAfter(DateTime.now())) {
        await _notificationService.scheduleNotification(
          id: pickupId.hashCode,
          title: 'Pickup Reminder',
          body: 'Your ${_selectedWasteType!} pickup is scheduled in 1 hour',
          scheduledDate: reminderTime,
          payload: '{"type": "pickup_reminder", "pickupId": "$pickupId"}',
        );
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pickup scheduled successfully!'),
            backgroundColor: AppColors.primary,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to history screen
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
          ),
        );

        // Navigate back to home
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to schedule pickup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
