import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wastemanagement2/app_auth_provider.dart';
import 'package:wastemanagement2/firebase_service.dart';
import 'package:wastemanagement2/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class RecyclablesScreen extends StatefulWidget {
  const RecyclablesScreen({Key? key}) : super(key: key);

  @override
  _RecyclablesScreenState createState() => _RecyclablesScreenState();
}

class _RecyclablesScreenState extends State<RecyclablesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  String? _selectedMaterialType;
  File? _image;
  bool _isLoading = false;

  final List<String> _materialTypes = [
    'Plastic',
    'Metal',
    'Paper',
    'Glass',
    'Electronics',
    'Textiles',
    'Other'
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _postRecyclable() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMaterialType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select material type')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = Provider.of<AppAuthProvider>(context, listen: false).user;
    final firebaseService = FirebaseService();

    // In a real app, you would upload the image to Firebase Storage
    // and get the download URL to store in Firestore
    final recyclableData = {
      'userId': user?.uid,
      'userEmail': user?.email,
      'title': _titleController.text,
      'description': _descriptionController.text,
      'materialType': _selectedMaterialType,
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'quantity': int.tryParse(_quantityController.text) ?? 1,
      'imageUrl': _image != null ? 'placeholder_url' : null,
      'status': 'available',
    };

    try {
      await firebaseService.postRecyclable(recyclableData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recyclable posted successfully!')),
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
        title: const Text('Post Recyclables'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sell Recyclable Materials',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Post your recyclable materials for companies to purchase',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _image == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to add photo',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_image!, fit: BoxFit.cover),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Material Type',
                  prefixIcon: Icon(Icons.category),
                ),
                value: _selectedMaterialType,
                items: _materialTypes
                    .map(
                      (type) => DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMaterialType = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a material type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _postRecyclable,
                  child: _isLoading
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : Text('Post Recyclable'),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
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