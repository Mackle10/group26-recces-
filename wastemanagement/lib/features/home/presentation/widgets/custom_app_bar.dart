import 'package:flutter/material.dart';
import 'package:wastemanagement/core/constants/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onLogout;

  const CustomAppBar({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        'Waste Management',
        style: TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      backgroundColor: AppColors.primary,
      elevation: 0,
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // Add notification logic here
          },
          color: AppColors.white,
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: onLogout,
          color: AppColors.white,
          tooltip: 'Logout',
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
