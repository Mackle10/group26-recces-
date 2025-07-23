import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/home_dashboard_screen.dart';
import 'screens/company_dashboard_screen.dart';
import 'screens/recyclables_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/support_screen.dart';
import 'screens/history_screen.dart';
import 'screens/admin_panel_screen.dart';
import 'screens/map_screen.dart';
import 'screens/faq_screen.dart';
import 'screens/UserRedirectWrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const WasteManagementApp());
}

class WasteManagementApp extends StatelessWidget {
  const WasteManagementApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Waste Management',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const UserRedirectWrapper(),

      // Static named routes that don't need arguments
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/recyclables': (context) => const RecyclablesScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/support': (context) => const SupportScreen(),
        '/history': (context) => const HistoryScreen(),
        '/admin_panel': (context) => const AdminPanelScreen(),
        '/map': (context) => const MapScreen(),
        '/faq': (context) => const FAQScreen(),
      },

      // Routes that require arguments
      onGenerateRoute: (settings) {
        if (settings.name == '/profile') {
          final args = settings.arguments as Map<String, String>;
          return MaterialPageRoute(
            builder: (context) => ProfileScreen(
              name: args['name'] ?? 'Unknown',
              email: args['email'] ?? 'unknown@example.com',
              userType: args['userType'] ?? 'Client',
            ),
          );
        }

        if (settings.name == '/homeDashboard') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => HomeDashboardScreen(
              name: args['name'],
              lastStatus: args['lastStatus'],
              lastDate: args['lastDate'],
              userType: args['userType'],
            ),
          );
        }

        if (settings.name == '/companyDashboard') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => CompanyDashboardScreen(
              name: args['name'],
              lastStatus: args['lastStatus'],
              lastDate: args['lastDate'],
              userType: args['userType'],
            ),
          );
        }

        return null;
      },

      // Catch unknown routes
      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Not Found')),
          body: const Center(child: Text('404 - Page Not Found')),
        ),
      ),
    );
  }
}
