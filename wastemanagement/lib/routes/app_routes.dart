import 'package:wastemanagement/features/auth/presentation/screens/login_screen.dart';
import 'package:wastemanagement/features/auth/presentation/screens/register_screen.dart';
import 'package:wastemanagement/features/company/enhanced_company_dashboard.dart';
import 'package:wastemanagement/features/home/presentation/screens/home_screen.dart';
import 'package:wastemanagement/features/home/presentation/screens/plain_intro_screen.dart';
import 'package:wastemanagement/features/pickup/presentation/screens/schedule_pickup_screen.dart';
import 'package:wastemanagement/features/recyclable/presentation/screens/enhanced_recyclables_marketplace.dart';
import 'package:wastemanagement/features/recyclable/presentation/screens/enhanced_sell_screen.dart';
import 'package:wastemanagement/features/payment/presentation/screens/payment_screen.dart';
import 'package:wastemanagement/features/map/presentation/screens/map_screen.dart';
import 'package:wastemanagement/features/demo/pickup_flow_demo.dart';

class AppRoutes {
  static const initial = '/';
  static const intro = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const schedulePickup = '/schedule-pickup';
  static const companyDashboard = '/company-dashboard';
  static const recyclablesMarketplace = '/recyclables';
  static const payment = '/payment';
  static const map = '/map';
  static const pickupFlowDemo = '/pickup-flow-demo';

  static final routes = {
    '/': (context) => const PlainIntroScreen(),
    '/login': (context) => const LoginScreen(),
    '/register': (context) => const RegisterScreen(),
    '/home': (context) => const HomeScreen(),
    '/schedule-pickup': (context) => const SchedulePickupScreen(),
    '/company-dashboard': (context) => const EnhancedCompanyDashboard(),
    '/recyclables': (context) => const EnhancedRecyclablesMarketplace(),
    '/sell': (context) => const EnhancedSellScreen(),
    '/payment': (context) => const PaymentScreen(),
    '/map': (context) => const MapScreen(),
    '/pickup-flow-demo': (context) => const PickupFlowDemo(),
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