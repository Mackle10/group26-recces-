import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wastemanagement/core/constants/app_colors.dart';
import 'package:wastemanagement/core/constants/app_strings.dart';
import 'package:wastemanagement/core/utils/validators.dart';
import 'package:wastemanagement/widgets/custom_button.dart';
import 'package:wastemanagement/widgets/custom_textfield.dart';
import 'package:wastemanagement/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:wastemanagement/routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty || Validators.validateEmail(_emailController.text) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid email address'),
          backgroundColor: AppColors.secondary,
        ),
      );
      return;
    }

    try {
      context.read<AuthBloc>().add(
            ForgotPasswordEvent(email: _emailController.text),
          );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password reset email sent'),
          backgroundColor: AppColors.lightGreen1,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.secondary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFa8e063), Color(0xFF56ab2f)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.secondary,
                ),
              );
            } else if (state is Authenticated) {
              final role = state.role;
              Navigator.pushReplacementNamed(context, role == "company" ? AppRoutes.companyDashboard : AppRoutes.home);
            }
          },
          builder: (context, state) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Cute Illustration/Icon
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 54,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.recycling,
                          size: 64,
                          color: Color(0xFF56ab2f),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome Back! 👋',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Log in to continue your eco journeyXXX',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Login Form Card
                    Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              CustomTextField(
                                initialValue: "<Email>",
                                controller: _emailController,
                                labelText: AppStrings.email,
                                prefixIcon: Icons.email_outlined,
                                iconColor: Color(0xFF56ab2f),
                                keyboardType: TextInputType.emailAddress,
                                validator: Validators.validateEmail,
                                fillColor: AppColors.lightGreen2.withOpacity(0.15),
                              ),
                              const SizedBox(height: 18),
                              CustomTextField(
                                initialValue: "<Password>",
                                controller: _passwordController,
                                labelText: AppStrings.password,
                                prefixIcon: Icons.lock_outlined,
                                iconColor: Color(0xFF56ab2f),
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Color(0xFF56ab2f),
                                  ),
                                  onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                                ),
                                validator: Validators.validatePassword,
                                fillColor: AppColors.lightGreen2.withOpacity(0.15),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: state is AuthLoading ? null : _resetPassword,
                                  child: Text(
                                    AppStrings.forgotPassword,
                                    style: TextStyle(
                                      color: Color(0xFF56ab2f),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              CustomButton(
                                text: AppStrings.login,
                                isLoading: state is AuthLoading,
                                backgroundColor: Color(0xFF56ab2f),
                                textColor: Colors.white,
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    context.read<AuthBloc>().add(
                                          LoginEvent(
                                            email: _emailController.text,
                                            password: _passwordController.text,
                                          ),
                                        );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Footer Section
                    Padding(
                      padding: const EdgeInsets.only(top: 28),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppStrings.noAccount,
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(
                                context, AppRoutes.register),
                            child: Text(
                              AppStrings.register,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}