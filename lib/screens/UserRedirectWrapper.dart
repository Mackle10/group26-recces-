import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_dashboard_screen.dart';
import 'company_dashboard_screen.dart';
import 'login_screen.dart';

class UserRedirectWrapper extends StatelessWidget {
  const UserRedirectWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!authSnapshot.hasData || authSnapshot.data == null) {
          return const LoginScreen(); // Not logged in
        }

        final uid = authSnapshot.data!.uid;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const Scaffold(body: Center(child: Text('User data not found.')));
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final userType = userData['userType'] ?? 'Client';
            final name = userData['name'] ?? 'User';
            final lastStatus = userData['lastStatus'] ?? 'Pending';
            final lastDate = userData['lastDate'] ?? 'Unknown';

            // Delay navigation to after build completes
            WidgetsBinding.instance.addPostFrameCallback((_) {
              print('UserRedirectWrapper: userType = ' + userType);
              print('UserRedirectWrapper: userData = ' + userData.toString());
              if (userType == 'Client' || userType == 'Home') {
                print('Redirecting to /homeDashboard with args: ' + userData.toString());
                Navigator.pushReplacementNamed(context, '/homeDashboard', 
                arguments: {
                  'name': userData['name'],
                  'lastStatus': userData['lastStatus'],
                  'lastDate': userData['lastDate'],
                  'userType': userData['userType'],
                }
                );
              } else if (userType == 'Company') {
                print('Redirecting to /companyDashboard with args: ' + {
                  'name': name,
                  'lastStatus': lastStatus,
                  'lastDate': lastDate,
                  'userType': userType,
                }.toString());
                Navigator.pushReplacementNamed(context, '/companyDashboard', arguments: {
                  'name': name,
                  'lastStatus': lastStatus,
                  'lastDate': lastDate,
                  'userType': userType,
                });
              }
            });

            // Return placeholder while navigating
            return const Scaffold(body: Center(child: Text('Redirecting...')));
          },
        );
      },
    );
  }
}
