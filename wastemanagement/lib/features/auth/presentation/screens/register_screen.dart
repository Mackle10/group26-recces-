import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wastemanagement/core/constants/app_colors.dart';
import 'package:wastemanagement/core/constants/app_strings.dart';
import 'package:wastemanagement/core/utils/validators.dart';
import 'package:wastemanagement/widgets/custom_button.dart';
import 'package:wastemanagement/widgets/custom_textfield.dart';
import 'package:wastemanagement/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:wastemanagement/routes/app_routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.secondary,
              ),
            );
          } else if (state is Authenticated) {
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.only(top: 40, bottom: 32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.app_registration,
                        size: 80,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.createAccount,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.registerSubtitle,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.black.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Form Section
                Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: AppColors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CustomTextField(
                            controller: _nameController,
                            labelText: AppStrings.fullName,
                            prefixIcon: Icons.person_outline,
                            iconColor: AppColors.primary,
                            validator: Validators.validateName,
                            fillColor: AppColors.lightGreen2.withOpacity(0.2),
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _emailController,
                            labelText: AppStrings.email,
                            prefixIcon: Icons.email_outlined,
                            iconColor: AppColors.primary,
                            keyboardType: TextInputType.emailAddress,
                            validator: Validators.validateEmail,
                            fillColor: AppColors.lightGreen2.withOpacity(0.2),
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _phoneController,
                            labelText: AppStrings.phoneNumber,
                            prefixIcon: Icons.phone_outlined,
                            iconColor: AppColors.primary,
                            keyboardType: TextInputType.phone,
                            validator: Validators.validatePhone,
                            fillColor: AppColors.lightGreen2.withOpacity(0.2),
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _passwordController,
                            labelText: AppStrings.password,
                            prefixIcon: Icons.lock_outline,
                            iconColor: AppColors.primary,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword 
                                    ? Icons.visibility_off 
                                    : Icons.visibility,
                                color: AppColors.primary,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            validator: Validators.validatePassword,
                            fillColor: AppColors.lightGreen2.withOpacity(0.2),
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _confirmPasswordController,
                            labelText: AppStrings.confirmPassword,
                            prefixIcon: Icons.lock_outline,
                            iconColor: AppColors.primary,
                            obscureText: _obscureConfirmPassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword 
                                    ? Icons.visibility_off 
                                    : Icons.visibility,
                                color: AppColors.primary,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                            validator: (value) => Validators.validateConfirmPassword(
                              value,
                              _passwordController.text,
                            ),
                            fillColor: AppColors.lightGreen2.withOpacity(0.2),
                          ),
                          const SizedBox(height: 24),
                          CustomButton(
                            text: AppStrings.register,
                            isLoading: state is AuthLoading,
                            backgroundColor: AppColors.primary,
                            textColor: AppColors.white,
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                context.read<AuthBloc>().add(
                                  RegisterEvent(
                                    name: _nameController.text,
                                    email: _emailController.text,
                                    phone: _phoneController.text,
                                    password: _passwordController.text,
                                  ),
                                );
                                Navigator.pushReplacementNamed(context, AppRoutes.home);
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
                  padding: const EdgeInsets.only(top: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.alreadyHaveAccount,
                        style: TextStyle(
                          color: AppColors.black.withOpacity(0.6),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.login,
                        ),
                        child: Text(
                          AppStrings.login,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}