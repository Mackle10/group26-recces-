import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
// import 'package:wastemanagement/core/constants/firebase_constants.dart';
// O11 import 'package:wastemanagement/core/constants/firebase_constants.dart';
import 'package:wastemanagement/core/constants/app_colors.dart';
// O11 import 'package:wastemanagement/core/constants/app_strings.dart';
import 'package:wastemanagement/routes/app_routes.dart';
import 'package:wastemanagement/routes/route_generator.dart';
import 'package:wastemanagement/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:wastemanagement/features/auth/domain/auth_repo.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(
        authRepository: FirebaseAuthRepository(),
      ),
      child: MaterialApp(
        title: 'Waste Management',
        theme: ThemeData(
          primarySwatch: Colors.green,
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            secondary: AppColors.secondary,
          ),
          scaffoldBackgroundColor: AppColors.background,
        ),
        initialRoute: AppRoutes.intro,
        routes: AppRoutes.routes,
        onGenerateRoute: RouteGenerator.generateRoute,
        debugShowCheckedModeBanner: false,
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
