import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wastemanagement/core/constants/app_colors.dart';
import 'package:wastemanagement/core/services/history_service.dart';
import 'package:wastemanagement/data/models/pickup_history_model.dart';
import 'package:wastemanagement/features/history/presentation/widgets/pickup_card.dart';
import 'package:wastemanagement/features/history/presentation/widgets/statistics_card.dart';
import 'package:wastemanagement/features/history/presentation/screens/pickup_details_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HistoryService _historyService = HistoryService();
  String _selectedFilter = 'all';
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Pickup History',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.date_range, color: Colors.white),
            onPressed: _showDateRangePicker,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Statistics Section
          Container(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<Map<String, dynamic>>(
              future: _historyService.getPickupStatistics(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return StatisticsCard(statistics: snapshot.data!);
                }
                return const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
          // History List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHistoryList('all'),
                _buildHistoryList('pending'),
                _buildHistoryList('in_progress'),
                _buildHistoryList('completed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(String status) {
    Stream<List<PickupHistoryModel>> stream;
    
    if (status == 'all') {
      stream = _historyService.getUserPickupHistory();
    } else {
      stream = _historyService.getPickupHistoryByStatus(status);
    }

    return StreamBuilder<List<PickupHistoryModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading history',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        List<PickupHistoryModel> pickups = snapshot.data ?? [];

        // Apply date range filter if selected
        if (_selectedDateRange != null) {
          pickups = pickups.where((pickup) {
            return pickup.scheduledDate.isAfter(_selectedDateRange!.start) &&
                pickup.scheduledDate.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
          }).toList();
        }

        if (pickups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  status == 'all' 
                      ? 'No pickup history yet'
                      : 'No ${status.replaceAll('_', ' ')} pickups',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your pickup requests will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
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
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PickupCard(
                  pickup: pickup,
                  onTap: () => _navigateToDetails(pickup),
                  onStatusUpdate: (newStatus) => _updatePickupStatus(pickup.id, newStatus),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _navigateToDetails(PickupHistoryModel pickup) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PickupDetailsScreen(pickup: pickup),
      ),
    );
  }

  void _updatePickupStatus(String pickupId, String newStatus) async {
    try {
      await _historyService.updatePickupStatus(pickupId, newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pickup status updated to $newStatus'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Pickups'),
              leading: Radio<String>(
                value: 'all',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('This Week'),
              leading: Radio<String>(
                value: 'week',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                    _selectedDateRange = DateTimeRange(
                      start: DateTime.now().subtract(const Duration(days: 7)),
                      end: DateTime.now(),
                    );
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('This Month'),
              leading: Radio<String>(
                value: 'month',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                    _selectedDateRange = DateTimeRange(
                      start: DateTime.now().subtract(const Duration(days: 30)),
                      end: DateTime.now(),
                    );
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedFilter = 'all';
                _selectedDateRange = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDateRangePicker() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _selectedFilter = 'custom';
      });
    }
  }
}