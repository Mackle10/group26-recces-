// O11 import 'package:flutter/material.dart';
// O11 import 'package:flutter_bloc/flutter_bloc.dart';
// O11 import 'package:firebase_auth/firebase_auth.dart';
// O11 import 'package:flutter_login/flutter_login.dart';
// O11 import 'package:wastemanagement/core/constants/app_colors.dart';
// O11 import 'package:wastemanagement/features/auth/presentation/bloc/auth_bloc.dart';
// O11 import 'package:wastemanagement/routes/app_routes.dart';
// O11 import 'package:google_sign_in/google_sign_in.dart';

// O11 class AuthGate extends StatelessWidget {
// O11   // Google Sign-In Configuration
// O11   final GoogleSignIn _googleSignIn = GoogleSignIn(
// O11     clientId: "327523805214-q657uqr9m7v23382p4keorc962pmppgs.apps.googleusercontent.com", // Update with your actual web client ID
// O11     scopes: ['email', 'profile'],
// O11   );

// O11   Future<UserCredential?> _handleGoogleSignIn() async {
// O11     try {
// O11       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
// O11       if (googleUser == null) return null;
    
// O11       final GoogleSignInAuthentication googleAuth = 
// O11           await googleUser.authentication;
    
// O11       final credential = GoogleAuthProvider.credential(
// O11         accessToken: googleAuth.accessToken,
// O11         idToken: googleAuth.idToken,
// O11       );
    
// O11       return await FirebaseAuth.instance.signInWithCredential(credential);
// O11     } catch (error) {
// O11       print("Google Sign-In Error: $error");
// O11       return null;
// O11     }
// O11   }

// O11   @override
// O11   Widget build(BuildContext context) {
// O11     return BlocBuilder<AuthBloc, AuthState>(
// O11       builder: (context, state) {
// O11         if (state is AuthLoading) {
// O11           return _buildLoadingScreen();
// O11         } else if (state is Authenticated) {
// O11           if (state.user.emailVerified) {
// O11             return const HomeScreen();
// O11           } else {
// O11             return _buildEmailVerificationScreen(state.user);
// O11           }
// O11         } else {
// O11           return _buildLoginScreen();
// O11         }
// O11       },
// O11     );
// O11   }

// O11   Widget _buildLoadingScreen() {
// O11     return Scaffold(
// O11       backgroundColor: AppColors.background,
// O11       body: Center(
// O11         child: CircularProgressIndicator(color: AppColors.primary),
// O11       ),
// O11     );
// O11   }

// O11   Widget _buildEmailVerificationScreen(User user) {
// O11     return Scaffold(
// O11       backgroundColor: AppColors.background,
// O11       body: Center(
// O11         child: Column(
// O11           mainAxisAlignment: MainAxisAlignment.center,
// O11           children: [
// O11             Icon(Icons.email, size: 80, color: AppColors.primary),
// O11             const SizedBox(height: 20),
// O11             Text(
// O11               'Verify Your Email',
// O11               style: TextStyle(
// O11                 fontSize: 24,
// O11                 fontWeight: FontWeight.bold,
// O11                 color: AppColors.primary,
// O11               ),
// O11             ),
// O11             const SizedBox(height: 20),
// O11             Padding(
// O11               padding: const EdgeInsets.symmetric(horizontal: 40),
// O11               child: Text(
// O11                 'We\'ve sent a verification link to ${user.email}. '
// O11                 'Please check your inbox and verify your email address.',
// O11                 textAlign: TextAlign.center,
// O11                 style: TextStyle(color: AppColors.black.withOpacity(0.7)),
// O11             ),
// O11             const SizedBox(height: 30),
// O11             CustomButton(
// O11               text: 'Resend Verification',
// O11               onPressed: () => context.read<AuthBloc>().add(SendEmailVerificationEvent()),
// O11               backgroundColor: AppColors.secondary,
// O11               textColor: AppColors.black,
// O11             ),
// O11             const SizedBox(height: 20),
// O11             TextButton(
// O11               onPressed: () => context.read<AuthBloc>().add(LogoutEvent()),
// O11               child: Text(
// O11                 'Sign Out',
// O11                 style: TextStyle(color: AppColors.primary),
// O11               ),
// O11             ),
// O11           ],
// O11         ),
// O11       ),
// O11     );
// O11   }

// O11   Widget _buildLoginScreen() {
// O11     return FlutterLogin(
// O11       title: 'Waste Management',
// O11       logo: 'assets/images/logo.png',
// O11       theme: LoginTheme(
// O11         primaryColor: AppColors.primary,
// O11         accentColor: AppColors.secondary,
// O11         buttonTheme: LoginButtonTheme(
// O11           backgroundColor: AppColors.primary,
// O11         ),
// O11       ),
// O11       onLogin: (loginData) {
// O11         context.read<AuthBloc>().add(
// O11           LoginRequested(loginData.name, loginData.password),
// O11         );
// O11         return null;
// O11       },
// O11       onSignup: (signupData) {
// O11         context.read<AuthBloc>().add(
// O11           RegisterRequested(
// O11             email: signupData.name,
// O11             password: signupData.password,
// O11             fullName: signupData.additionalSignupData?['name'] ?? '',
// O11             phoneNumber: signupData.additionalSignupData?['phone'] ?? '',
// O11           ),
// O11         );
// O11         return null;
// O11       },
// O11       additionalSignupFields: [
// O11         UserFormField(
// O11           keyName: 'name',
// O11           displayName: 'Full Name',
// O11           icon: Icon(Icons.person, color: AppColors.primary),
// O11         ),
// O11         UserFormField(
// O11           keyName: 'phone',
// O11           displayName: 'Phone Number',
// O11           icon: Icon(Icons.phone, color: AppColors.primary),
// O11           keyboardType: TextInputType.phone,
// O11         ),
// O11       ],
// O11       loginProviders: [
// O11         LoginProvider(
// O11           icon: Icons.g_mobiledata,
// O11           label: 'Google',
// O11           callback: () async {
// O11             final userCredential = await _handleGoogleSignIn();
// O11             if (userCredential != null) {
// O11               context.read<AuthBloc>().add(GoogleSignInRequested(userCredential));
// O11             }
// O11             return null;
// O11           },
// O11         ),
// O11       ],
// O11       onSubmitAnimationCompleted: () {
// O11         Navigator.of(context).pushReplacementNamed(AppRoutes.home);
// O11       },
// O11       onRecoverPassword: (email) {
// O11         context.read<AuthBloc>().add(ForgotPasswordEvent(email));
// O11         return null;
// O11       },
// O11     );
// O11   }
// O11 }