import 'package:flutter/material.dart';
import 'package:wastemanagement/core/constants/app_colors.dart';
import 'package:wastemanagement/routes/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:wastemanagement/core/providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildProfileSection(),
            const SizedBox(height: 24),

            // Appearance Section
            _buildAppearanceSection(),
            const SizedBox(height: 24),

            // Preferences Section
            _buildPreferencesSection(),
            const SizedBox(height: 24),

            // Account Section
            _buildAccountSection(),
            const SizedBox(height: 24),

            // About Section
            _buildAboutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'Guest User',
                      style: TextStyle(
                        color: AppColors.black.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.edit, color: AppColors.primary),
            title: const Text('Edit Profile'),
            subtitle: const Text('Update your personal information'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to edit profile screen
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.palette,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Appearance',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return SwitchListTile(
                secondary: const Icon(
                  Icons.dark_mode,
                  color: AppColors.primary,
                ),
                title: const Text('Dark Mode'),
                subtitle: const Text('Switch between light and dark theme'),
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.setTheme(value);
                },
                activeColor: AppColors.primary,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.settings,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Preferences',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            secondary: const Icon(
              Icons.notifications,
              color: AppColors.primary,
            ),
            title: const Text('Notifications'),
            subtitle: const Text('Receive push notifications'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.location_on, color: AppColors.primary),
            title: const Text('Location Services'),
            subtitle: const Text('Allow location access for pickup services'),
            value: _locationEnabled,
            onChanged: (value) {
              setState(() {
                _locationEnabled = value;
              });
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_circle,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Account',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.security, color: AppColors.primary),
            title: const Text('Privacy & Security'),
            subtitle: const Text('Manage your privacy settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to privacy settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock, color: AppColors.primary),
            title: const Text('Change Password'),
            subtitle: const Text('Update your account password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to change password screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Sign out of your account'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showLogoutDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'About',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.description, color: AppColors.primary),
            title: const Text('Terms of Service'),
            subtitle: const Text('Read our terms and conditions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to terms of service
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: AppColors.primary),
            title: const Text('Privacy Policy'),
            subtitle: const Text('Read our privacy policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to privacy policy
            },
          ),
          ListTile(
            leading: const Icon(Icons.help, color: AppColors.primary),
            title: const Text('Help & Support'),
            subtitle: const Text('Get help and contact support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to help screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppColors.primary),
            title: const Text('App Version'),
            subtitle: const Text('Version 1.0.0'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Show app version details
            },
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Handle logout
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
