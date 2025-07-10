import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wastemanagement/core/utils/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:wastemanagement/features/auth/domain/entities/user_entity.dart';
import 'package:wastemanagement/features/auth/domain/auth_repo.dart';

class AuthRepositoryImpl implements AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthRepositoryImpl({
    firebase_auth.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.standard();

  @override
  Stream<UserEntity?> get user {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      return firebaseUser == null ? null : firebaseUser.toUserEntity();
    });
  }

  @override
  UserEntity? get currentUser {
    return _firebaseAuth.currentUser?.toUserEntity();
  }

  @override
  Future<Either<Failure, void>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return const Right(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(Failure.fromFirebaseAuthException(e));
    } catch (e) {
      return Left(Failure(message: 'Login failed. Please try again.'));
    }
  }

  @override
  Future<Either<Failure, void>> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user profile with additional information
      await userCredential.user?.updateDisplayName(fullName);
      
      // You might want to store phone number in Firestore separately
      return const Right(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(Failure.fromFirebaseAuthException(e));
    } catch (e) {
      return Left(Failure(message: 'Registration failed. Please try again.'));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return const Right(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(Failure.fromFirebaseAuthException(e));
    } catch (e) {
      return Left(Failure(message: 'Password reset failed. Please try again.'));
    }
  }

  @override
  Future<Either<Failure, void>> sendEmailVerification() async {
    try {
      await _firebaseAuth.currentUser?.sendEmailVerification();
      return const Right(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(Failure.fromFirebaseAuthException(e));
    } catch (e) {
      return Left(Failure(message: 'Failed to send verification email.'));
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    await _firebaseAuth.currentUser?.reload();
    return _firebaseAuth.currentUser?.emailVerified ?? false;
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
      return const Right(null);
    } catch (e) {
      return Left(Failure(message: 'Logout failed. Please try again.'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      await _firebaseAuth.currentUser?.delete();
      return const Right(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(Failure.fromFirebaseAuthException(e));
    } catch (e) {
      return Left(Failure(message: 'Account deletion failed. Please try again.'));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      await _firebaseAuth.currentUser?.updateDisplayName(displayName);
      if (photoUrl != null) {
        await _firebaseAuth.currentUser?.updatePhotoURL(photoUrl);
      }
      return const Right(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(Failure.fromFirebaseAuthException(e));
    } catch (e) {
      return Left(Failure(message: 'Profile update failed. Please try again.'));
    }
  }

  @override
  Future<Either<Failure, String>> getIdToken() async {
    try {
      final token = await _firebaseAuth.currentUser?.getIdToken();
      return token != null
          ? Right(token)
          : Left(Failure(message: 'Failed to get authentication token.'));
    } catch (e) {
      return Left(Failure(message: 'Failed to get authentication token.'));
    }
  }
}

extension on firebase_auth.User {
  UserEntity toUserEntity() {
    return UserEntity(
      id: uid,
      email: email,
      name: displayName,
      phoneNumber: phoneNumber,
      photoUrl: photoURL,
      emailVerified: emailVerified,
    );
  }
}