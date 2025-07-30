import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wastemanagement/core/constants/app_colors.dart';
import 'package:wastemanagement/data/models/pickup_history_model.dart';
import 'package:wastemanagement/core/services/history_service.dart';
import 'package:wastemanagement/core/services/notification_service.dart';

class PickupDetailsScreen extends StatefulWidget {
  final PickupHistoryModel pickup;

  const PickupDetailsScreen({
    super.key,
    required this.pickup,
  });

  @override
  State<PickupDetailsScreen> createState() => _PickupDetailsScreenState();
}

class _PickupDetailsScreenState extends State<PickupDetailsScreen> {
  final HistoryService _historyService = HistoryService();
  final NotificationService _notificationService = NotificationService();
  late GoogleMapController _mapController;
  late PickupHistoryModel _pickup;

  @override
  void initState() {
    super.initState();
    _pickup = widget.pickup;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Pickup Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_pickup.isPending)
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined),
                      SizedBox(width: 8),
                      Text('Edit Pickup'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Cancel Pickup', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            _buildStatusHeader(),
            
            // Basic Information
            _buildBasicInfoSection(),
            
            // Location Section
            if (_pickup.latitude != null && _pickup.longitude != null)
              _buildLocationSection(),
            
            // Company Information
            if (_pickup.companyName != null)
              _buildCompanySection(),
            
            // Completion Details
            if (_pickup.isCompleted)
              _buildCompletionSection(),
            
            // Timeline
            _buildTimelineSection(),
            
            // Action Buttons
            _buildActionButtons(),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getStatusColor(),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Icon(
            _getStatusIcon(),
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            _pickup.statusDisplayName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getStatusDescription(),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pickup Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.delete_outline,
              'Waste Type',
              _pickup.wasteTypeDisplayName,
            ),
            _buildInfoRow(
              Icons.schedule_outlined,
              'Scheduled Date',
              DateFormat('EEEE, MMM dd, yyyy • hh:mm a').format(_pickup.scheduledDate),
            ),
            if (_pickup.address != null)
              _buildInfoRow(
                Icons.location_on_outlined,
                'Address',
                _pickup.address!,
              ),
            if (_pickup.notes != null)
              _buildInfoRow(
                Icons.note_outlined,
                'Notes',
                _pickup.notes!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  onMapCreated: (controller) => _mapController = controller,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_pickup.latitude!, _pickup.longitude!),
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('pickup_location'),
                      position: LatLng(_pickup.latitude!, _pickup.longitude!),
                      infoWindow: const InfoWindow(title: 'Pickup Location'),
                    ),
                  },
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanySection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assigned Company',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.business,
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
                        _pickup.companyName!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Waste Management Company',
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
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Completion Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_pickup.completedDate != null)
              _buildInfoRow(
                Icons.check_circle_outline,
                'Completed On',
                DateFormat('EEEE, MMM dd, yyyy • hh:mm a').format(_pickup.completedDate!),
              ),
            if (_pickup.weight != null)
              _buildInfoRow(
                Icons.scale_outlined,
                'Weight Collected',
                '${_pickup.weight!.toStringAsFixed(1)} kg',
              ),
            if (_pickup.price != null)
              _buildInfoRow(
                Icons.attach_money_outlined,
                'Amount Earned',
                'UGX ${_pickup.price!.toStringAsFixed(0)}',
                valueColor: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Timeline',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTimelineItem(
              'Pickup Requested',
              DateFormat('MMM dd, yyyy • hh:mm a').format(_pickup.scheduledDate),
              Icons.add_circle_outline,
              Colors.blue,
              isCompleted: true,
            ),
            if (_pickup.companyName != null)
              _buildTimelineItem(
                'Company Assigned',
                'Assigned to ${_pickup.companyName}',
                Icons.business_outlined,
                Colors.orange,
                isCompleted: true,
              ),
            if (_pickup.isInProgress || _pickup.isCompleted)
              _buildTimelineItem(
                'Pickup In Progress',
                'Collection started',
                Icons.local_shipping_outlined,
                Colors.blue,
                isCompleted: _pickup.isCompleted,
              ),
            if (_pickup.isCompleted)
              _buildTimelineItem(
                'Pickup Completed',
                DateFormat('MMM dd, yyyy • hh:mm a').format(_pickup.completedDate!),
                Icons.check_circle_outline,
                Colors.green,
                isCompleted: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    {bool isCompleted = false}
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCompleted ? color : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: isCompleted ? Colors.white : Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? Colors.black : Colors.grey.shade600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_pickup.isCompleted || _pickup.isCancelled) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_pickup.isPending) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _scheduleReminder,
                icon: const Icon(Icons.notifications_outlined),
                label: const Text('Set Reminder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _cancelPickup,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel Pickup'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
          if (_pickup.isInProgress) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _trackPickup,
                icon: const Icon(Icons.location_on_outlined),
                label: const Text('Track Pickup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (_pickup.status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (_pickup.status) {
      case 'pending':
        return Icons.schedule;
      case 'in_progress':
        return Icons.local_shipping;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusDescription() {
    switch (_pickup.status) {
      case 'pending':
        return 'Your pickup request is waiting to be assigned to a company';
      case 'in_progress':
        return 'A company is on the way to collect your waste';
      case 'completed':
        return 'Your waste has been successfully collected';
      case 'cancelled':
        return 'This pickup request has been cancelled';
      default:
        return 'Status unknown';
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _editPickup();
        break;
      case 'cancel':
        _cancelPickup();
        break;
    }
  }

  void _editPickup() {
    // TODO: Navigate to edit pickup screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit pickup feature coming soon!')),
    );
  }

  void _cancelPickup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Pickup'),
        content: const Text('Are you sure you want to cancel this pickup request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _historyService.cancelPickup(_pickup.id, 'Cancelled by user');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pickup cancelled successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to cancel pickup: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red[600]),
            ),
          ),
        ],
      ),
    );
  }

  void _scheduleReminder() async {
    DateTime reminderTime = _pickup.scheduledDate.subtract(const Duration(hours: 1));
    
    if (reminderTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot set reminder for past dates'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _notificationService.scheduleNotification(
        id: _pickup.id.hashCode,
        title: 'Pickup Reminder',
        body: 'Your ${_pickup.wasteTypeDisplayName} pickup is scheduled in 1 hour',
        scheduledDate: reminderTime,
        payload: '{"type": "pickup_reminder", "pickupId": "${_pickup.id}"}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder set successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to set reminder: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _trackPickup() {
    // TODO: Implement real-time tracking
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Real-time tracking feature coming soon!')),
    );
  }
}