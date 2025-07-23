import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  Future<void> _fetchCompanies() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('userType', isEqualTo: 'Company')
        .get();

    setState(() {
      _companies = snapshot.docs;
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

  void _submit() async {
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _selectedTime != null &&
        _selectedCompanyId != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final dateStr =
          "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
      final timeStr = _selectedTime!.format(context);

      try {
        await FirebaseFirestore.instance.collection('requests').add({
          'userId': user.uid,
          'name': user.displayName ?? user.email ?? 'Client',
          'address': _streetController.text.trim(),
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
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit request: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select date, time, and company.')),
      );
    }
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
                TextFormField(
                  controller: _streetController,
                  decoration: const InputDecoration(
                    labelText: 'Street Name',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Please enter your street name' : null,
                ),
                const SizedBox(height: 12),

                // Company dropdown
                _companies.isNotEmpty
                    ? DropdownButtonFormField<String>(
                        value: _selectedCompanyId,
                        items: _companies.map((companyDoc) {
                          final name = companyDoc['name'] ?? companyDoc['email'] ?? 'Unnamed Company';
                          return DropdownMenuItem<String>(
                            value: companyDoc.id,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedCompanyId = value),
                        decoration: const InputDecoration(
                          labelText: 'Choose Garbage Collector',
                          prefixIcon: Icon(Icons.business),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null ? 'Please choose a garbage collection company' : null,
                      )
                    : const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No companies available yet. Try again later.',
                          style: TextStyle(color: Colors.red),
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
