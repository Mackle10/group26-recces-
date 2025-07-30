import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wastemanagement/core/constants/app_colors.dart';
import 'package:wastemanagement/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:wastemanagement/core/services/pickup_assignment_service.dart';
import 'package:wastemanagement/routes/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:badges/badges.dart' as badges;
import 'package:cloud_firestore/cloud_firestore.dart';

class EnhancedCompanyDashboard extends StatefulWidget {
  const EnhancedCompanyDashboard({super.key});

  @override
  State<EnhancedCompanyDashboard> createState() => _EnhancedCompanyDashboardState();
}

class _EnhancedCompanyDashboardState extends State<EnhancedCompanyDashboard>
    with SingleTickerProviderStateMixin {
  late GoogleMapController _mapController;
  late TabController _tabController;
  final PickupAssignmentService _assignmentService = PickupAssignmentService();
  
  final LatLng _companyLocation = const LatLng(0.333229, 32.568032);
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<Map<String, dynamic>> _assignedPickups = [];
  Map<String, dynamic> _companyStats = {};
  bool _isLoadingStats = false;
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeMarkers();
    _loadCompanyStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeMarkers() {
    _markers = {
      Marker(
        markerId: const MarkerId('company'),
        position: _companyLocation,
        infoWindow: const InfoWindow(title: 'Your Company Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    };
  }

  Future<void> _loadCompanyStats() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final stats = await _assignmentService.getCompanyStatistics(currentUser.uid);
        setState(() {
          _companyStats = stats;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading statistics: $e')),
      );
    } finally {
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Company Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppColors.primary,
          elevation: 0,
          actions: [
            // Availability Toggle
            Switch(
              value: _isAvailable,
              onChanged: (value) async {
                setState(() {
                  _isAvailable = value;
                });
                try {
                  await _assignmentService.updateCompanyAvailability(
                    currentUser!.uid,
                    value,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value ? 'You are now available for pickups' : 'You are now unavailable',
                      ),
                      backgroundColor: value ? Colors.green : Colors.orange,
                    ),
                  );
                } catch (e) {
                  setState(() {
                    _isAvailable = !value;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update availability: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              activeColor: Colors.white,
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadCompanyStats,
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () => _showLogoutDialog(context),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.dashboard),
                    const SizedBox(width: 4),
                    const Text('Overview'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_shipping),
                    const SizedBox(width: 4),
                    const Text('Pickups'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.map),
                    const SizedBox(width: 4),
                    const Text('Map'),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildPickupsTab(),
            _buildMapTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Availability Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isAvailable ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isAvailable ? Icons.check_circle : Icons.pause_circle,
                      color: _isAvailable ? Colors.green : Colors.orange,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isAvailable ? 'Available for Pickups' : 'Currently Unavailable',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _isAvailable 
                              ? 'You will receive new pickup assignments'
                              : 'Toggle availability to receive pickups',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Statistics Cards
          if (_isLoadingStats)
            const Center(child: CircularProgressIndicator())
          else
            _buildStatisticsGrid(),

          const SizedBox(height: 16),

          // Quick Actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionButton(
                          'View Pickups',
                          Icons.local_shipping,
                          AppColors.primary,
                          () => _tabController.animateTo(1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionButton(
                          'Open Map',
                          Icons.map,
                          Colors.blue,
                          () => _tabController.animateTo(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: _buildQuickActionButton(
                      'Marketplace',
                      Icons.store,
                      Colors.green,
                      () => Navigator.pushNamed(context, AppRoutes.recyclablesMarketplace),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          'Total Pickups',
          _companyStats['totalPickups']?.toString() ?? '0',
          Icons.local_shipping,
          Colors.blue,
        ),
        _buildStatCard(
          'In Progress',
          _companyStats['inProgressPickups']?.toString() ?? '0',
          Icons.pending_actions,
          Colors.orange,
        ),
        _buildStatCard(
          'Assigned',
          _companyStats['assignedPickups']?.toString() ?? '0',
          Icons.assignment,
          Colors.purple,
        ),
        _buildStatCard(
          'Completion Rate',
          '${(_companyStats['completionRate'] ?? 0.0).toStringAsFixed(1)}%',
          Icons.check_circle,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildPickupsTab() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('Please log in to view pickups'));
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _assignmentService.getCompanyPickupAssignments(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading pickups',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final pickups = snapshot.data ?? [];
        setState(() {
          _assignedPickups = pickups;
        });

        if (pickups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No Assigned Pickups',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  _isAvailable 
                      ? 'New pickups will appear here when assigned'
                      : 'Enable availability to receive pickups',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pickups.length,
            itemBuilder: (context, index) {
              final pickup = pickups[index];
              return _buildPickupCard(pickup);
            },
          ),
        );
      },
    );
  }

  Widget _buildPickupCard(Map<String, dynamic> pickup) {
    final scheduledDate = pickup['scheduledDate'] as Timestamp?;
    final assignedDate = pickup['assignedAt'] as Timestamp?;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getWasteTypeColor(pickup['wasteType']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getWasteTypeIcon(pickup['wasteType']),
                    color: _getWasteTypeColor(pickup['wasteType']),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pickup['userName'] ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        pickup['wasteType'] ?? 'General',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(pickup['status']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    pickup['status'] == 'assigned' ? 'New' : pickup['status'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Address
            if (pickup['address'] != null) ...[
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      pickup['address'],
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Scheduled Date
            if (scheduledDate != null) ...[
              Row(
                children: [
                  Icon(Icons.schedule_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Scheduled: ${DateFormat('MMM dd, yyyy • hh:mm a').format(scheduledDate.toDate())}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Contact Info
            if (pickup['userPhone'] != null) ...[
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    pickup['userPhone'],
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openDirections(pickup),
                    icon: const Icon(Icons.directions, size: 16),
                    label: const Text('Directions'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _callCustomer(pickup),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updatePickupStatus(pickup),
                    icon: Icon(
                      pickup['status'] == 'assigned' ? Icons.play_arrow : Icons.check,
                      size: 16,
                    ),
                    label: Text(
                      pickup['status'] == 'assigned' ? 'Start' : 'Complete',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pickup['status'] == 'assigned' ? Colors.blue : Colors.green,
                      foregroundColor: Colors.white,
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

  Widget _buildMapTab() {
    return GoogleMap(
      onMapCreated: (controller) => _mapController = controller,
      initialCameraPosition: CameraPosition(
        target: _companyLocation,
        zoom: 12,
      ),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }

  Color _getWasteTypeColor(String? wasteType) {
    switch (wasteType?.toLowerCase()) {
      case 'recyclable':
        return Colors.green;
      case 'hazardous':
        return Colors.red;
      case 'organic':
        return Colors.brown;
      case 'electronic':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getWasteTypeIcon(String? wasteType) {
    switch (wasteType?.toLowerCase()) {
      case 'recyclable':
        return Icons.recycling;
      case 'hazardous':
        return Icons.warning;
      case 'organic':
        return Icons.eco;
      case 'electronic':
        return Icons.electrical_services;
      default:
        return Icons.delete_outline;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'assigned':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _openDirections(Map<String, dynamic> pickup) async {
    final lat = pickup['latitude'];
    final lng = pickup['longitude'];
    
    if (lat != null && lng != null) {
      final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
      try {
        if (await canLaunch(url)) {
          await launch(url);
        } else {
          throw 'Could not launch $url';
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open directions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not available for this pickup'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _callCustomer(Map<String, dynamic> pickup) async {
    final phone = pickup['userPhone'];
    if (phone != null && phone.isNotEmpty) {
      final url = 'tel:$phone';
      try {
        if (await canLaunch(url)) {
          await launch(url);
        } else {
          throw 'Could not launch $url';
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not make call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not available'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _updatePickupStatus(Map<String, dynamic> pickup) async {
    final currentStatus = pickup['status'];
    String newStatus;
    
    if (currentStatus == 'assigned') {
      newStatus = 'in_progress';
    } else if (currentStatus == 'in_progress') {
      newStatus = 'completed';
    } else {
      return; // Already completed.
    }

    try {
      await _assignmentService.updatePickupStatus(pickup['id'], newStatus);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pickup status updated to $newStatus'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh statistics
      _loadCompanyStats();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
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
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthBloc>().add(LogoutRequested());
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
