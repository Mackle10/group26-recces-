import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:wastemanagement/core/constants/app_colors.dart';
import 'package:wastemanagement/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:wastemanagement/routes/app_routes.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthGate extends StatelessWidget {
  // Google Sign-In Configuration
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: "327523805214-q657uqr9m7v23382p4keorc962pmppgs.apps.googleusercontent.com", // Update with your actual web client ID
    scopes: ['email', 'profile'],
  );

  Future<UserCredential?> _handleGoogleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (error) {
      print("Google Sign-In Error: $error");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return _buildLoadingScreen();
        } else if (state is Authenticated) {
          if (state.user.emailVerified) {
            return const HomeScreen();
          } else {
            return _buildEmailVerificationScreen(state.user);
          }
        } else {
          return _buildLoginScreen();
        }
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _buildEmailVerificationScreen(User user) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.email, size: 80, color: AppColors.primary),
            const SizedBox(height: 20),
            Text(
              'Verify Your Email',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'We\'ve sent a verification link to ${user.email}. '
                'Please check your inbox and verify your email address.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.black.withOpacity(0.7)),
            ),
            const SizedBox(height: 30),
            CustomButton(
              text: 'Resend Verification',
              onPressed: () => context.read<AuthBloc>().add(SendEmailVerificationEvent()),
              backgroundColor: AppColors.secondary,
              textColor: AppColors.black,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => context.read<AuthBloc>().add(LogoutEvent()),
              child: Text(
                'Sign Out',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginScreen() {
    return FlutterLogin(
      title: 'Waste Management',
      logo: 'assets/images/logo.png',
      theme: LoginTheme(
        primaryColor: AppColors.primary,
        accentColor: AppColors.secondary,
        buttonTheme: LoginButtonTheme(
          backgroundColor: AppColors.primary,
        ),
      ),
      onLogin: (loginData) {
        context.read<AuthBloc>().add(
          LoginRequested(loginData.name, loginData.password),
        );
        return null;
      },
      onSignup: (signupData) {
        context.read<AuthBloc>().add(
          RegisterRequested(
            email: signupData.name,
            password: signupData.password,
            fullName: signupData.additionalSignupData?['name'] ?? '',
            phoneNumber: signupData.additionalSignupData?['phone'] ?? '',
          ),
        );
        return null;
      },
      additionalSignupFields: [
        UserFormField(
          keyName: 'name',
          displayName: 'Full Name',
          icon: Icon(Icons.person, color: AppColors.primary),
        ),
        UserFormField(
          keyName: 'phone',
          displayName: 'Phone Number',
          icon: Icon(Icons.phone, color: AppColors.primary),
          keyboardType: TextInputType.phone,
        ),
      ],
      loginProviders: [
        LoginProvider(
          icon: Icons.g_mobiledata,
          label: 'Google',
          callback: () async {
            final userCredential = await _handleGoogleSignIn();
            if (userCredential != null) {
              context.read<AuthBloc>().add(GoogleSignInRequested(userCredential));
            }
            return null;
          },
        ),
      ],
      onSubmitAnimationCompleted: () {
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      },
      onRecoverPassword: (email) {
        context.read<AuthBloc>().add(ForgotPasswordEvent(email));
        return null;
      },
    );
  }
}