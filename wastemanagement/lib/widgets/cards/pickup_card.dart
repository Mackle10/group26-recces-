import 'package:flutter/material.dart';

class PickupCard extends StatelessWidget {
  final String companyName;
  final String estimatedTime;
  final String status;
  final VoidCallback? onTap;

  const PickupCard({
    super.key,
    required this.companyName,
    required this.estimatedTime,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                companyName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 4),
                  Text(estimatedTime),
                ],
              ),
              const SizedBox(height: 8),
              Chip(
                label: Text(status),
                backgroundColor: _getStatusColor(status),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color? _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange[100];
      case 'scheduled':
        return Colors.blue[100];
      case 'completed':
        return Colors.green[100];
      default:
        return Colors.grey[100];
    }
  }
}