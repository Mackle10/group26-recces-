import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecyclablesMarketplace extends StatelessWidget {
  const RecyclablesMarketplace({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recyclables Marketplace')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('recyclables').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No recyclables available.'));
          }
          final recyclables = snapshot.data!.docs;
          return ListView.builder(
            itemCount: recyclables.length,
            itemBuilder: (context, index) {
              final data = recyclables[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['name'] ?? 'No name'),
                subtitle: Text(data['description'] ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}
