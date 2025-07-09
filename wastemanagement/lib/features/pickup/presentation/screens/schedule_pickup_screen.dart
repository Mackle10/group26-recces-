import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waste_management_app/core/constants/app_strings.dart';
import 'package:waste_management_app/features/pickup/presentation/bloc/pickup_bloc.dart';

class SchedulePickupScreen extends StatefulWidget {
  const SchedulePickupScreen({super.key});

  @override
  State<SchedulePickupScreen> createState() => _SchedulePickupScreenState();
}

class _SchedulePickupScreenState extends State<SchedulePickupScreen> {
  DateTime? _selectedDate;
  String? _selectedWasteType;
  final List<String> _wasteTypes = ['General', 'Recyclable', 'Hazardous'];

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
      appBar: AppBar(title: const Text(AppStrings.schedulePickup)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedWasteType,
              decoration: const InputDecoration(labelText: AppStrings.wasteType),
              items: _wasteTypes.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedWasteType = newValue;
                });
              },
              validator: (value) => value == null ? AppStrings.selectWasteType : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _selectDate(context),
              child: Text(_selectedDate == null
                  ? AppStrings.selectDate
                  : '${AppStrings.selectedDate}: ${_selectedDate!.toLocal()}'.split(' ')[0]),
            ),
            const SizedBox(height: 20),
            BlocConsumer<PickupBloc, PickupState>(
              listener: (context, state) {
                if (state is PickupScheduled) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text(AppStrings.pickupScheduled)),
                  );
                  Navigator.pop(context);
                } else if (state is PickupError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              builder: (context, state) {
                if (state is PickupLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ElevatedButton(
                  onPressed: _selectedDate == null || _selectedWasteType == null
                      ? null
                      : () {
                          context.read<PickupBloc>().add(
                                SchedulePickupEvent(
                                  wasteType: _selectedWasteType!,
                                  pickupDate: _selectedDate!,
                                ),
                              );
                        },
                  child: const Text(AppStrings.schedulePickup),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}