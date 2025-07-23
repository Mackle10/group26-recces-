import 'package:flutter/material.dart';

class CompanyRequestsScreen extends StatelessWidget {
  const CompanyRequestsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mock data for demonstration
    final List<Map<String, String>> urgentRequests = [
      {
        'home': 'Alice',
        'street': '123 Main St',
        'transport': 'Small Truck',
      },
      {
        'home': 'Bob',
        'street': '456 Oak Ave',
        'transport': 'Large Truck',
      },
      {
        'home': 'Carol',
        'street': '789 Pine Rd',
        'transport': 'Van',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Immediate Collection Requests'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: urgentRequests.isEmpty
          ? const Center(child: Text('No immediate requests.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: urgentRequests.length,
              itemBuilder: (context, index) {
                final req = urgentRequests[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.home, color: Colors.green),
                    title: Text('${req['home']} - ${req['street']}'),
                    subtitle: Text('Transport: ${req['transport']}'),
                  ),
                );
              },
            ),
    );
  }
} 