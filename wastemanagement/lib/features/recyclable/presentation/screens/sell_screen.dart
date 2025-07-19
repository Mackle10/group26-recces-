import 'package:flutter/material.dart';
import 'package:wastemanagement/core/constants/app_strings.dart';
// Ensure that the file 'app_strings.dart' exists and contains the 'AppStrings' class with the required static string fields.
import 'package:wastemanagement/features/recyclable/presentation/bloc/recyclable_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SellScreen extends StatefulWidget {
  final List<dynamic>? recyclableItems; // adjust type as needed
  final dynamic location; // adjust type as needed

  const SellScreen({
    super.key,
    this.recyclableItems,
    this.location,
  });

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedMaterial;
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final List<String> _materials = ['Plastic', 'Metal', 'Paper', 'Glass'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.sellRecyclables)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedMaterial,
                decoration: const InputDecoration(labelText: AppStrings.materialType),
                items: _materials.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedMaterial = newValue;
                  });
                },
                validator: (value) => value == null ? AppStrings.selectMaterial : null,
              ),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: AppStrings.quantity),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.enterQuantity;
                  }
                  if (double.tryParse(value) == null) {
                    return AppStrings.validQuantity;
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: AppStrings.pricePerUnit),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.enterPrice;
                  }
                  if (double.tryParse(value) == null) {
                    return AppStrings.validPrice;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              BlocConsumer<RecyclableBloc, RecyclableState>(
                listener: (context, state) {
                  if (state is RecyclablePosted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text(AppStrings.listingCreated)),
                    );
                    Navigator.pop(context);
                  } else if (state is RecyclableError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message)),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is RecyclableLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        context.read<RecyclableBloc>().add(
                              PostRecyclableEvent(
                                materialType: _selectedMaterial!,
                                quantity: double.parse(_quantityController.text),
                                pricePerUnit: double.parse(_priceController.text),
                              ),
                            );
                      }
                    },
                    child: const Text(AppStrings.postListing),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}