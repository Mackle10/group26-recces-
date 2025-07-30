import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wastemanagement/core/constants/app_colors.dart';
import 'package:wastemanagement/routes/app_routes.dart';

class PickupFlowDemo extends StatelessWidget {
  const PickupFlowDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Pickup Flow Demo',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Real-time Pickup Assignment System',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This demo shows how users and companies are connected in real-time. When a user schedules a pickup, it automatically appears on the nearest company\'s dashboard with route navigation.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // User Flow Section
            const Text(
              'User Flow',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildFlowStep(
              '1',
              'Schedule Pickup',
              'User creates a pickup request with location and waste details',
              Icons.schedule,
              Colors.blue,
              () => Navigator.pushNamed(context, AppRoutes.schedulePickup),
            ),
            const SizedBox(height: 8),
            _buildFlowStep(
              '2',
              'Automatic Assignment',
              'System finds nearest available company and assigns pickup',
              Icons.auto_awesome,
              Colors.orange,
              null,
            ),
            const SizedBox(height: 8),
            _buildFlowStep(
              '3',
              'Real-time Notification',
              'Both user and company receive instant notifications',
              Icons.notifications_active,
              Colors.green,
              null,
            ),
            const SizedBox(height: 24),

            // Company Flow Section
            const Text(
              'Company Flow',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildFlowStep(
              '4',
              'View Dashboard',
              'Company sees assigned pickups in real-time dashboard',
              Icons.dashboard,
              Colors.purple,
              () => Navigator.pushNamed(context, AppRoutes.companyDashboard),
            ),
            const SizedBox(height: 8),
            _buildFlowStep(
              '5',
              'Get Directions',
              'Click pickup to get route navigation to user location',
              Icons.directions,
              Colors.teal,
              null,
            ),
            const SizedBox(height: 8),
            _buildFlowStep(
              '6',
              'Update Status',
              'Company updates pickup status (in progress → completed)',
              Icons.check_circle,
              Colors.green,
              null,
            ),
            const Spacer(),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.schedulePickup),
                    icon: const Icon(Icons.person, size: 20),
                    label: const Text('User View'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.companyDashboard),
                    icon: const Icon(Icons.business, size: 20),
                    label: const Text('Company View'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowStep(
    String stepNumber,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Step Number
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    stepNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Arrow for clickable items
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}