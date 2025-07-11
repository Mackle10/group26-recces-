import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wastemanagement2/app_auth_provider.dart';
import 'package:wastemanagement2/firebase_service.dart';
import 'package:wastemanagement2/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super. key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  File? _profileImage;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = Provider.of<AppAuthProvider>(context, listen: false).user;
    if (user != null) {
      final userData = await FirebaseService().getUserData(user.uid);
      setState(() {
        _nameController.text = userData['name'] ?? '';
        _emailController.text = user.email ?? '';
        _phoneController.text = userData['phone'] ?? '';
        _addressController.text = userData['address'] ?? '';
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = Provider.of<AppAuthProvider>(context, listen: false).user;
    if (user != null) {
      try {
        // In a real app, you would upload the image to Firebase Storage
        // and get the download URL to store in Firestore
        await FirebaseService().updateUserData(user.uid, {
          'name': _nameController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );

        setState(() {
          _isEditing = false;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    await Provider.of<AppAuthProvider>(context, listen: false).logout();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppAuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() => _isEditing = true);
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : (user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : null),
                    child: user?.photoURL == null && _profileImage == null
                        ? const Icon(Icons.person, size: 60)
                        : null,
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_isEditing) _buildEditForm(),
            if (!_isEditing) _buildProfileInfo(),
            const SizedBox(height: 24),
            if (_isEditing)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Changes'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            if (_isEditing)
              TextButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _loadUserData(); // Reset changes
                  });
                },
                child: const Text('Cancel'),
              ),
            const SizedBox(height: 16),
            if (!_isEditing)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Logout'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.person, color: AppTheme.primaryColor),
          title: const Text('Name'),
          subtitle: Text(
            _nameController.text.isNotEmpty ? _nameController.text : 'Not provided',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.email, color: AppTheme.primaryColor),
          title: const Text('Email'),
          subtitle: Text(
            _emailController.text.isNotEmpty ? _emailController.text : 'Not provided',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.phone, color: AppTheme.primaryColor),
          title: const Text('Phone'),
          subtitle: Text(
            _phoneController.text.isNotEmpty ? _phoneController.text : 'Not provided',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.location_on, color: AppTheme.primaryColor),
          title: const Text('Address'),
          subtitle: Text(
            _addressController.text.isNotEmpty ? _addressController.text : 'Not provided',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
            ),
            enabled: false, // Email shouldn't be editable
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              prefixIcon: Icon(Icons.location_on),
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your address for pickups';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}