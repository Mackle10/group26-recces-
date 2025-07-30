import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wastemanagement/core/constants/app_colors.dart';
import 'package:wastemanagement/data/models/pickup_history_model.dart';

class PickupCard extends StatelessWidget {
  final PickupHistoryModel pickup;
  final VoidCallback onTap;
  final Function(String) onStatusUpdate;

  const PickupCard({
    super.key,
    required this.pickup,
    required this.onTap,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Waste Type Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getWasteTypeColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getWasteTypeIcon(),
                      color: _getWasteTypeColor(),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Waste Type and Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pickup.wasteTypeDisplayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy • hh:mm a').format(pickup.scheduledDate),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      pickup.statusDisplayName,
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
              
              // Address (if available)
              if (pickup.address != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        pickup.address!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // Company Info (if available)
              if (pickup.companyName != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.business_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      pickup.companyName!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // Weight and Price (if completed)
              if (pickup.isCompleted && (pickup.weight != null || pickup.price != null)) ...[
                Row(
                  children: [
                    if (pickup.weight != null) ...[
                      Icon(
                        Icons.scale_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${pickup.weight!.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (pickup.price != null) ...[
                      Icon(
                        Icons.attach_money_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      Text(
                        'UGX ${pickup.price!.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // Action Buttons
              if (pickup.isPending || pickup.isInProgress) ...[
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (pickup.isPending) ...[
                      TextButton(
                        onPressed: () => _showCancelDialog(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Colors.red[600]),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    TextButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('View Details'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getWasteTypeColor() {
    switch (pickup.wasteType.toLowerCase()) {
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

  IconData _getWasteTypeIcon() {
    switch (pickup.wasteType.toLowerCase()) {
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

  Color _getStatusColor() {
    switch (pickup.status) {
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

  void _showCancelDialog(BuildContext context) {
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
            onPressed: () {
              Navigator.pop(context);
              onStatusUpdate('cancelled');
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
}