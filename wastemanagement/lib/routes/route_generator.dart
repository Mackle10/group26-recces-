import 'package:flutter/material.dart';
import '../features/recyclable/presentation/screens/recyclable_list_screen.dart';
import '../features/recyclable/presentation/screens/sell_screen.dart';
import 'app_routes.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.recyclableList:
        return MaterialPageRoute(
          builder: (_) => const RecyclableListScreen(),
          settings: settings,
        );
      case AppRoutes.sellScreen:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => SellScreen(
            recyclableItems: args?['items'],
            location: args?['location'],
          ),
          settings: settings,
        );
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Route not found')),
      ),
    );
  }
}