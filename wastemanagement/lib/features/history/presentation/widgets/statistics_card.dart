import 'package:flutter/material.dart';
import 'package:wastemanagement/core/constants/app_colors.dart';

class StatisticsCard extends StatelessWidget {
  final Map<String, dynamic> statistics;

  const StatisticsCard({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Your Impact',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Main Statistics Row
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Pickups',
                    statistics['totalPickups']?.toString() ?? '0',
                    Icons.local_shipping_outlined,
                    AppColors.primary,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Completed',
                    statistics['completedPickups']?.toString() ?? '0',
                    Icons.check_circle_outline,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Pending',
                    statistics['pendingPickups']?.toString() ?? '0',
                    Icons.schedule_outlined,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Weight and Earnings Row
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Weight',
                    '${(statistics['totalWeight'] ?? 0.0).toStringAsFixed(1)} kg',
                    Icons.scale_outlined,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Total Earnings',
                    'UGX ${(statistics['totalEarnings'] ?? 0.0).toStringAsFixed(0)}',
                    Icons.attach_money_outlined,
                    Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Completion Rate Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Completion Rate',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(statistics['completionRate'] ?? 0.0).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (statistics['completionRate'] ?? 0.0) / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 6,
                ),
              ],
            ),
            
            // Waste Type Breakdown (if available)
            if (statistics['wasteTypeBreakdown'] != null && 
                (statistics['wasteTypeBreakdown'] as Map).isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Waste Types',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: (statistics['wasteTypeBreakdown'] as Map<String, dynamic>)
                    .entries
                    .map((entry) => _buildWasteTypeChip(entry.key, entry.value))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildWasteTypeChip(String type, int count) {
    Color chipColor = _getWasteTypeColor(type);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getWasteTypeIcon(type),
            size: 14,
            color: chipColor,
          ),
          const SizedBox(width: 4),
          Text(
            '$type ($count)',
            style: TextStyle(
              fontSize: 12,
              color: chipColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getWasteTypeColor(String type) {
    switch (type.toLowerCase()) {
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

  IconData _getWasteTypeIcon(String type) {
    switch (type.toLowerCase()) {
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
}