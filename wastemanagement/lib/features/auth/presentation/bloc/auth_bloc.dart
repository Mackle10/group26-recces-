import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wastemanagement/features/auth/domain/auth_repo.dart';
import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:wastemanagement/data/models/user_model.dart';


part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  StreamSubscription<User?>? _authSubscription;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    // Setup auth state listener
    _authSubscription = authRepository.user.listen((User? user) {
      add(AuthStateChanged(user));
    });

    // Event handlers
    on<AuthStateChanged>(_handleAuthStateChanged);
    on<LoginRequested>(_handleLogin);
    on<RegisterRequested>(_handleRegister);
    on<PasswordResetRequested>(_handlePasswordReset);
    on<LogoutRequested>(_handleLogout);
    on<DeleteAccountRequested>(_handleAccountDeletion);
    on<EmailVerificationSent>(_handleSendEmailVerification);
    on<VerifyEmailRequested>(_handleVerifyEmail);

    // New event handlers
    on<LoginEvent>(_handleLoginEvent);
    on<RegisterEvent>(_handleRegisterEvent);
    on<ForgotPasswordEvent>(_handleForgotPasswordEvent);
  }

  Future<void> _handleAuthStateChanged(
    AuthStateChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (event.user != null) {
      if (event.user!.emailVerified) {
        // Fetch role from Firestore
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(event.user!.uid).get();
        final role = userDoc.data()?['role'] ?? 'user';
        emit(Authenticated(event.user!, role));
      } else {
        emit(UnverifiedEmail(event.user!));
      }
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _handleLogin(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await authRepository.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapFirebaseError(e)));
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError('Login failed. Please try again.'));
      emit(Unauthenticated());
    }
  }

  Future<void> _handleRegister(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await authRepository.createUserWithEmailAndPassword(
        role: event.role,
        email: event.email,
        password: event.password,
        fullName: event.fullName,
        phoneNumber: event.phoneNumber,
      );
      add(EmailVerificationSent());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapFirebaseError(e)));
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError('Registration failed. Please try again.'));
      emit(Unauthenticated());
    }
  }

  Future<void> _handlePasswordReset(
    PasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await authRepository.sendPasswordResetEmail(event.email);
      emit(PasswordResetSent());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapFirebaseError(e)));
    } catch (e) {
      emit(AuthError('Password reset failed. Please try again.'));
    }
  }

  Future<void> _handleLogout(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await authRepository.signOut();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError('Logout failed. Please try again.'));
    }
  }

  Future<void> _handleAccountDeletion(
    DeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await authRepository.deleteAccount();
      emit(AccountDeleted());
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError('Account deletion failed. Please try again.'));
    }
  }

  Future<void> _handleSendEmailVerification(
    EmailVerificationSent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await authRepository.sendEmailVerification();
      emit(VerificationEmailSent());
    } catch (e) {
      emit(AuthError('Failed to send verification email.'));
    }
  }

  Future<void> _handleVerifyEmail(
    VerifyEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.getCurrentUser();
      if (user != null && user.emailVerified) {
        // Fetch role from Firestore
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final role = userDoc.data()?['role'] ?? 'user';
        emit(Authenticated(user, role));
      } else if (user != null) {
        emit(UnverifiedEmail(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError('Email verification check failed.'));
    }
  }

  // New event handlers for O11 events
  Future<void> _handleLoginEvent(
    LoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await authRepository.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      final user = await authRepository.getCurrentUser();
      // Fetch role from Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      final role = userDoc.data()?['role'] ?? 'user';
      emit(Authenticated(user!, role));
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapFirebaseError(e)));
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError('Login failed. Please try again.'));
      emit(Unauthenticated());
    }
  }

  Future<void> _handleRegisterEvent(
    RegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
        fullName: event.name,
        phoneNumber: event.phone,
        role: event.role, // pass role
      );
      // Fetch role from Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      final role = userDoc.data()?['role'] ?? 'user';
      emit(Authenticated(user, role));
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapFirebaseError(e)));
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError('Registration failed. Please try again.'));
      emit(Unauthenticated());
    }
  }

  Future<void> _handleForgotPasswordEvent(
    ForgotPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await authRepository.sendPasswordResetEmail(event.email);
      emit(PasswordResetSent());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapFirebaseError(e)));
    } catch (e) {
      emit(AuthError('Password reset failed. Please try again.'));
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'requires-recent-login':
        return 'Please log in again to perform this action.';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
