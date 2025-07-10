import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:wastemanagement/core/constants/firebase_constants.dart';
import 'package:wastemanagement/core/constants/firebase_constants.dart';
import 'package:wastemanagement/core/constants/app_colors.dart';
import 'package:wastemanagement/core/constants/app_strings.dart';
import 'package:wastemanagement/routes/app_routes.dart';
import 'package:wastemanagement/routes/route_generator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
         title: 'Waste Management',
      theme: ThemeData(
        primarySwatch: Colors.green,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
        scaffoldBackgroundColor: AppColors.background,
      ),
      initialRoute: AppRoutes.login,
      onGenerateRoute: RouteGenerator.generateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}