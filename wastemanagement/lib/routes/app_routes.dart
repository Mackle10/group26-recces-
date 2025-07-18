import 'package:wastemanagement/features/auth/presentation/screens/login_screen.dart';
import 'package:wastemanagement/features/auth/presentation/screens/register_screen.dart';
import 'package:wastemanagement/features/company/company_dashboard.dart';
import 'package:wastemanagement/features/home/presentation/screens/home_screen.dart';
import 'package:wastemanagement/features/pickup/presentation/screens/schedule_pickup_screen.dart';

class AppRoutes {
  static const initial = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const schedulePickup = '/schedule-pickup';
  static const companyDashboard = '/company-dashboard';
  static const recyclablesMarketplace = '/recyclables';
  static const payment = '/payment';

  static final routes = {
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    home: (context) => const HomeScreen(),
    schedulePickup: (context) => const SchedulePickupScreen(),
    companyDashboard: (context) => const CompanyDashboard(),
    // Add other routes here
  };
// O11 abstract class AppRoutes {
  static const String recyclableList = '/recyclable-list';
  static const String sellScreen = '/sell';
  
  static String getRecyclableListRoute() => recyclableList;
  static String getSellScreenRoute() => sellScreen;
// O11 }
}
// need attention