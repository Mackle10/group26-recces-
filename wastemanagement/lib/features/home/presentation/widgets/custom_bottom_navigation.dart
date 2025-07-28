import 'package:flutter/material.dart';
import 'package:wastemanagement/core/constants/app_colors.dart';

class CustomBottomNavigation extends StatelessWidget {
  final VoidCallback onSettingsTap;

  const CustomBottomNavigation({super.key, required this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
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
      onTap: (index) {
        if (index == 2) {
          onSettingsTap();
        }
      },
    );
  }
}
