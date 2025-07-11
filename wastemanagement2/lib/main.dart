import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:wastemanagement2/app_auth_provider.dart' as my_auth;
import 'package:wastemanagement2/screens/login_screen.dart';
import 'package:wastemanagement2/screens/register_screen.dart';
import 'package:wastemanagement2/screens/home_screen.dart';
import 'package:wastemanagement2/screens/schedule_pickup_screen.dart';
import 'package:wastemanagement2/screens/profile_screen.dart';
import 'package:wastemanagement2/screens/recyclables_screen.dart';
import 'package:wastemanagement2/screens/settings_screen.dart';
import 'package:wastemanagement2/firebase_service.dart';
import 'package:wastemanagement2/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => my_auth.AppAuthProvider()),
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
          '/home': (context) => const HomeScreen(),
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
    final AppAuthProvider = Provider.of<AppAuthProvider>(context);
    
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            return const LoginScreen();
          }
          return const HomeScreen();
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