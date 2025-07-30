import 'package:flutter/material.dart';
import 'package:wastemanagement/core/constants/app_colors.dart';
import 'package:wastemanagement/features/pickup/presentation/screens/schedule_pickup_screen.dart';
import 'package:wastemanagement/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wastemanagement/features/settings/presentation/screens/settings_screen.dart';
import 'package:wastemanagement/routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:wastemanagement/core/providers/theme_provider.dart';
import 'package:wastemanagement/features/history/presentation/screens/history_screen.dart';
import 'package:wastemanagement/core/services/notification_service.dart';
import 'package:badges/badges.dart' as badges;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is Unauthenticated) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.getBackgroundColor(
              themeProvider.isDarkMode,
            ),
            appBar: _buildAppBar(themeProvider),
            body: _buildBody(themeProvider),
            // floatingActionButton: _buildFloatingActionButton(),
            bottomNavigationBar: _buildBottomNavigationBar(),
          ),
        );
      },
    );
  }

  // AppBar Widget
  AppBar _buildAppBar(ThemeProvider themeProvider) {
    return AppBar(
      title: Text(
        'Waste Management',
        style: TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      backgroundColor: AppColors.getPrimaryColor(themeProvider.isDarkMode),
      elevation: 0,
      centerTitle: false,
      actions: [
        badges.Badge(
          badgeContent: const Text(
            '3',
            style: TextStyle(color: Colors.white, fontSize: 10),
          ),
          showBadge: true,
          badgeStyle: const badges.BadgeStyle(
            badgeColor: Colors.red,
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              _showNotificationsDialog();
            },
            color: AppColors.white,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            // Dispatch logout event
            context.read<AuthBloc>().add(LogoutRequested());
          },
          color: AppColors.white,
          tooltip: 'Logout',
        ),
      ],
    );
  }

  // Body Widget
  Widget _buildBody(ThemeProvider themeProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(themeProvider),
          const SizedBox(height: 30),
          _buildQuickActionsSection(),
          const SizedBox(height: 30),
          _buildRecyclablesMarketplaceSection(themeProvider),
        ],
      ),
    );
  }

  // Welcome Section
  Widget _buildWelcomeSection(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode
            ? AppColors.darkSurface
            : AppColors.lightGreen1.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.getSurfaceColor(
              themeProvider.isDarkMode,
            ),
            child: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.person,
              size: 30,
              color: AppColors.getPrimaryColor(themeProvider.isDarkMode),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getPrimaryColor(themeProvider.isDarkMode),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Let\'s manage waste responsibly',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.getTextSecondaryColor(
                    themeProvider.isDarkMode,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Quick Actions Section
  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Schedule',
                icon: Icons.schedule,
                color: AppColors.lightGreen2,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SchedulePickupScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                title: 'View Map',
                icon: Icons.map,
                color: AppColors.secondary,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.map);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Company Dashboard',
                icon: Icons.business,
                color: Colors.purple,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.companyDashboard);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                title: 'Pickup Flow Demo',
                icon: Icons.play_circle_filled,
                color: Colors.orange,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.pickupFlowDemo);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Action Card Widget
  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
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
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Recyclables Marketplace Section
  Widget _buildRecyclablesMarketplaceSection(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recyclables Marketplace',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.getPrimaryColor(themeProvider.isDarkMode),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.recyclablesMarketplace);
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.getSurfaceColor(themeProvider.isDarkMode),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.recycling,
                  size: 40,
                  color: AppColors.getPrimaryColor(themeProvider.isDarkMode),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sell Your Recyclables',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getPrimaryColor(
                            themeProvider.isDarkMode,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Turn waste into cash',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.getTextSecondaryColor(
                            themeProvider.isDarkMode,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.getPrimaryColor(themeProvider.isDarkMode),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Floating Action Button
  // Widget _buildFloatingActionButton() {
  //   return FloatingActionButton(
  //     onPressed: () {
  //       // Add floating action button logic
  //     },
  //     backgroundColor: AppColors.primary,
  //     child: const Icon(Icons.add, color: Colors.white),
  //   );
  // }

  // Bottom Navigation Bar
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });

        // Handle navigation based on index
        switch (index) {
          case 0: // Home
            // Already on home
            break;
          case 1: // Histories
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            );
            break;
          case 2: // Settings
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
            break;
        }
      },
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
    );
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.notifications_outlined, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Notifications'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNotificationItem(
                'Pickup Scheduled',
                'Your recyclable waste pickup is scheduled for tomorrow at 10:00 AM',
                Icons.schedule,
                Colors.blue,
                '2 hours ago',
              ),
              const Divider(),
              _buildNotificationItem(
                'Payment Received',
                'You earned UGX 15,000 from your last recyclable pickup',
                Icons.attach_money,
                Colors.green,
                '1 day ago',
              ),
              const Divider(),
              _buildNotificationItem(
                'Pickup Completed',
                'Your general waste has been successfully collected',
                Icons.check_circle,
                Colors.green,
                '2 days ago',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to full notifications screen
            },
            child: const Text('View All'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    String title,
    String message,
    IconData icon,
    Color iconColor,
    String time,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
