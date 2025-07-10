import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:waste_management_app/core/utils/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:waste_management_app/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  // Stream of authentication state changes
  Stream<UserEntity?> get user;

  // Current user
  UserEntity? get currentUser;

  // Email & Password Authentication
  Future<Either<Failure, void>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  });

  // Password Reset
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);

  // Email Verification
  Future<Either<Failure, void>> sendEmailVerification();
  Future<bool> isEmailVerified();

  // User Management
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, void>> deleteAccount();

  // User Data
  Future<Either<Failure, void>> updateUserProfile({
    String? displayName,
    String? photoUrl,
  });

  // Token Management
  Future<Either<Failure, String>> getIdToken();
}