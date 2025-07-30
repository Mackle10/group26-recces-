import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
// import 'package:wastemanagement/core/constants/firebase_constants.dart';
// O11 import 'package:wastemanagement/core/constants/firebase_constants.dart';
// O11 import 'package:wastemanagement/core/constants/app_strings.dart';
import 'package:wastemanagement/routes/app_routes.dart';
import 'package:wastemanagement/routes/route_generator.dart';
import 'package:wastemanagement/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:wastemanagement/features/auth/domain/auth_repo.dart';
import 'package:wastemanagement/core/providers/theme_provider.dart';
import 'package:wastemanagement/core/services/notification_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Initializing Firebase...'); // Debug log
  await dotenv.load(fileName: ".env");
  
  // Initialize timezone
  tz.initializeTimeZones();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully'); // Debug log
    
    // Initialize notification service
    await NotificationService().initialize();
    print('Notification service initialized successfully'); // Debug log
  } catch (e) {
    print('Firebase initialization failed: $e'); // Debug log
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              AuthBloc(authRepository: FirebaseAuthRepository()),
        ),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Waste Management',
            theme: themeProvider.getTheme(),
            initialRoute: AppRoutes.intro,
            routes: AppRoutes.routes,
            onGenerateRoute: RouteGenerator.generateRoute,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Directionality(
  //     textDirection: TextDirection.ltr,
  //     child: Scaffold(
  //       body: Column(
  //         children: [Text("heeloo")],
  //       )
  //     )
  //   );
  // }
}
