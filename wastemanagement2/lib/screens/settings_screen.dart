import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wastemanagement2/app_auth_provider.dart' as my_auth;
import 'package:wastemanagement2/theme.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'English';

  final List<String> _languages = ['English', 'Spanish', 'French', 'German'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Preferences'),
          _buildSwitchSetting(
            title: 'Enable Notifications',
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
              // In a real app, you would save this preference
            },
            icon: Icons.notifications,
          ),
          _buildSwitchSetting(
            title: 'Dark Mode',
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() => _darkModeEnabled = value);
              // In a real app, you would implement theme switching
            },
            icon: Icons.dark_mode,
          ),
          _buildDropdownSetting(
            title: 'Language',
            value: _selectedLanguage,
            items: _languages,
            onChanged: (value) {
              setState(() => _selectedLanguage = value!);
              // In a real app, you would implement localization
            },
            icon: Icons.language,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Account'),
          _buildListTileSetting(
            title: 'Change Password',
            icon: Icons.lock,
            onTap: () {
              // Implement password change functionality
              _showPasswordChangeDialog();
            },
          ),
          _buildListTileSetting(
            title: 'Privacy Policy',
            icon: Icons.privacy_tip,
            onTap: () => _launchUrl('https://example.com/privacy'),
          ),
          _buildListTileSetting(
            title: 'Terms of Service',
            icon: Icons.description,
            onTap: () => _launchUrl('https://example.com/terms'),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('About'),
          _buildListTileSetting(
            title: 'Share App',
            icon: Icons.share,
            onTap: _shareApp,
          ),
          _buildListTileSetting(
            title: 'Rate App',
            icon: Icons.star,
            onTap: () => _launchUrl(
                'https://play.google.com/store/apps/details?id=your.package.name'),
          ),
          _buildListTileSetting(
            title: 'Contact Support',
            icon: Icons.support_agent,
            onTap: () => _launchUrl('mailto:support@wastemanagement.com'),
          ),
          _buildListTileSetting(
            title: 'App Version',
            icon: Icons.info,
            trailing: const Text('1.0.0'),
            onTap: () {},
          ),
          const SizedBox(height: 40),
          Center(
            child: ElevatedButton(
              onPressed: () {
                Provider.of<my_auth.AppAuthProvider>(context, listen: false).logout();
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // changed from primary
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith( // changed from subtitle1
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildSwitchSetting({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildDropdownSetting({
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: items.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildListTileSetting({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  // Future<void> _shareApp() async {
  //   await Share.share(
  //     'Check out this Waste Management App!\nhttps://example.com/app',
  //     subject: 'Waste Management App',
  //   );
  // }

  Future<void> _showPasswordChangeDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }

              try {
                final user = Provider.of<AppAuthProvider>(context, listen: false).user;
                if (user != null) {
                  // Reauthenticate first
                  final credential = EmailAppAuthProvider.credential(
                    email: user.email!,
                    password: currentPasswordController.text,
                  );
                  await user.reauthenticateWithCredential(credential);

                  // Then update password
                  await user.updatePassword(newPasswordController.text);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password changed successfully!')),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            child: const Text('Update'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor, // changed from primary
            ),
          ),
        ],
      ),
    );
  }
}