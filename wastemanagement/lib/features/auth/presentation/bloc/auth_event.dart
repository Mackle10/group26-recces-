part of 'auth_bloc.dart';
import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

@immutable
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

// Triggered when auth state changes (auto-login)
class AuthStateChanged extends AuthEvent {
  final User? user;
  const AuthStateChanged(this.user);

  @override
  List<Object> get props => [user ?? Object()];
}

// User login attempt
class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  const LoginRequested(this.email, this.password);

  @override
  List<Object> get props => [email, password];
}

// New user registration
class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String phoneNumber;
  const RegisterRequested({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phoneNumber,
  });

  @override
  List<Object> get props => [email, password, fullName, phoneNumber];
}

/// Event triggered when a user requests a password reset (Forgot Password).
class PasswordResetRequested extends AuthEvent {
  final String email;
  const PasswordResetRequested(this.email);

  @override
  List<Object> get props => [email];
}

// User logout
class LogoutRequested extends AuthEvent {}

// Account deletion
class DeleteAccountRequested extends AuthEvent {}

// Email verification
class EmailVerificationSent extends AuthEvent {}
class VerifyEmailRequested extends AuthEvent {}