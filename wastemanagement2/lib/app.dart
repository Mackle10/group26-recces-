import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:wastemanagement2/app_auth_provider.dart';
import 'package:wastemanagement2/screens/login_screen.dart';
import 'package:wastemanagement2/screens/register_screen.dart';
import 'package:wastemanagement2/screens/home_screen.dart';
import 'package:wastemanagement2/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppAuthProvider(),
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
    
    if (AppAuthProvider.user != null) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}