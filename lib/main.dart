import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'FirebaseOptions.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:wastemanagement2/app_authProvider.dart' as my_auth;
import 'package:wastemanagement2/screens/LoginScreen.dart';
import 'package:wastemanagement2/screens/RegisterScreen.dart';
import 'package:wastemanagement2/screens/HomeScreen.dart';
import 'package:wastemanagement2/screens/SchedulePickupScreen.dart';
import 'package:wastemanagement2/screens/ProfileScreen.dart';
import 'package:wastemanagement2/screens/RecyclablesScreen.dart';
import 'package:wastemanagement2/screens/SettingsScreen.dart';
import 'package:wastemanagement2/FirebaseService.dart';
import 'package:wastemanagement2/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => my_auth.AuthProvider()),
        Provider(create: (_) => FirebaseService()),
      ],
      child: MaterialApp(
        title: 'Waste Management App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeContentScreen(),
          '/schedule-pickup': (context) => const SchedulePickupScreen(),
          '/recyclables': (context) => const RecyclablesScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            return const LoginScreen(); // ✅ FIXED: was `login_screen()`
          }
          return const HomeContentScreen();
        }
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
