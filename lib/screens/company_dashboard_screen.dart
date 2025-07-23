import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompanyDashboardScreen extends StatefulWidget {
  final String name;
  final String lastStatus;
  final String lastDate;
  final String userType;

  const CompanyDashboardScreen({
    Key? key,
    required this.name,
    required this.lastStatus,
    required this.lastDate,
    required this.userType,
  }) : super(key: key);

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _markAsCompleted(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .update({'status': 'Completed'});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request marked as completed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Dashboard'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('assignedCompanyId', isEqualTo: currentUserId)
            .orderBy('submittedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
                child: Text('Something went wrong while loading requests.'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No assigned requests yet.\nYou will see them here once a client chooses your company.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final doc = requests[index];
              final requestId = doc.id;
              final data = doc.data()! as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: ListTile(
                  title: Text('From: ${data['clientEmail'] ?? 'Client'}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: ${data['date']}  Time: ${data['time']}'),
                      Text('Urgency: ${data['urgency']}'),
                      Text('Address: ${data['address']}'),
                      Text('Status: ${data['status']}'),
                    ],
                  ),
                  trailing: data['status'] != 'Completed'
                      ? ElevatedButton(
                          onPressed: () => _markAsCompleted(requestId),
                          child: const Text('Mark Completed'),
                        )
                      : const Icon(Icons.check_circle, color: Colors.green),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
