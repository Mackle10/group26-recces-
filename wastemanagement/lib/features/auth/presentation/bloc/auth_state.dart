part of 'auth_bloc.dart';

@immutable
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

// Initial state
class AuthInitial extends AuthState {}

// Loading state
class AuthLoading extends AuthState {}

// Authenticated states
class Authenticated extends AuthState {
  final User user;
  const Authenticated(this.user);

  @override
  List<Object> get props => [user];
}

class UnverifiedEmail extends AuthState {
  final User user;
  const UnverifiedEmail(this.user);

  @override
  List<Object> get props => [user];
}

// Unauthenticated state
class Unauthenticated extends AuthState {}

// Success states
class PasswordResetSent extends AuthState {}
class VerificationEmailSent extends AuthState {}
class AccountDeleted extends AuthState {}

// Error state
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}