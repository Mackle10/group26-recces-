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
}