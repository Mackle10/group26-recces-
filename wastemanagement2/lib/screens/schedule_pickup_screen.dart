import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wastemanagement2/app_auth_provider.dart';
import 'package:wastemanagement2/firebase_service.dart';
import 'package:wastemanagement2/theme.dart';
import 'package:intl/intl.dart';

class SchedulePickupScreen extends StatefulWidget {
  const SchedulePickupScreen({Key? key}) : super(key: key);

  @override
  _SchedulePickupScreenState createState() => _SchedulePickupScreenState();
}

class _SchedulePickupScreenState extends State<SchedulePickupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedWasteType;
  bool _isLoading = false;

  final List<String> _wasteTypes = [
    'General Waste',
    'Recyclables',
    'Hazardous Waste',
    'Organic Waste',
    'Bulky Items'
  ];

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submitPickup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null || _selectedWasteType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = Provider.of<AppAuthProvider>(context, listen: false).user;
    final firebaseService = FirebaseService();

    final pickupData = {
      'userId': user?.uid,
      'userEmail': user?.email,
      'address': _addressController.text,
      'wasteType': _selectedWasteType,
      'notes': _notesController.text,
      'scheduledDate': DateFormat('yyyy-MM-dd').format(_selectedDate!),
      'scheduledTime': _selectedTime!.format(context),
      'status': 'pending',
    };

    try {
      await firebaseService.schedulePickup(pickupData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pickup scheduled successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Pickup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Schedule a Waste Pickup',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fill in the details to schedule a waste pickup from your location',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Pickup Address',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter pickup address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Waste Type',
                  prefixIcon: Icon(Icons.delete),
                ),
                value: _selectedWasteType,
                items: _wasteTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedWasteType = value);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select waste type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Pickup Date',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _selectedDate == null
                              ? 'Select date'
                              : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _selectTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Pickup Time',
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(
                          _selectedTime == null
                              ? 'Select time'
                              : _selectedTime!.format(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes (Optional)',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitPickup,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Schedule Pickup'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}