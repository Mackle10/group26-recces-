// O11 import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
// O11 import 'package:google_sign_in/google_sign_in.dart';
// O11 import 'package:wastemanagement/core/utils/failure.dart';
// O11 import 'package:dartz/dartz.dart';
// O11 import 'package:wastemanagement/features/auth/domain/entities/user_entity.dart';
// O11 import 'package:wastemanagement/features/auth/domain/auth_repo.dart';

// O11 class AuthRepositoryImpl implements AuthRepository {
// O11   final firebase_auth.FirebaseAuth _firebaseAuth;
// O11   final GoogleSignIn _googleSignIn;

// O11   AuthRepositoryImpl({
// O11     firebase_auth.FirebaseAuth? firebaseAuth,
// O11     GoogleSignIn? googleSignIn,
// O11   })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
// O11         _googleSignIn = googleSignIn ?? GoogleSignIn.standard();

// O11   @override
// O11   Stream<UserEntity?> get user {
// O11     return _firebaseAuth.authStateChanges().map((firebaseUser) {
// O11       return firebaseUser == null ? null : firebaseUser.toUserEntity();
// O11     });
// O11   }

// O11   @override
// O11   UserEntity? get currentUser {
// O11     return _firebaseAuth.currentUser?.toUserEntity();
// O11   }

// O11   @override
// O11   Future<Either<Failure, void>> signInWithEmailAndPassword({
// O11     required String email,
// O11     required String password,
// O11   }) async {
// O11     try {
// O11       await _firebaseAuth.signInWithEmailAndPassword(
// O11         email: email,
// O11         password: password,
// O11       );
// O11       return const Right(null);
// O11     } on firebase_auth.FirebaseAuthException catch (e) {
// O11       return Left(Failure.fromFirebaseAuthException(e));
// O11     } catch (e) {
// O11       return Left(Failure(message: 'Login failed. Please try again.'));
// O11     }
// O11   }

// O11   @override
// O11   Future<Either<Failure, void>> createUserWithEmailAndPassword({
// O11     required String email,
// O11     required String password,
// O11     required String fullName,
// O11     required String phoneNumber,
// O11   }) async {
// O11     try {
// O11       final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
// O11         email: email,
// O11         password: password,
// O11       );

// O11       // Update user profile with additional information
// O11       await userCredential.user?.updateDisplayName(fullName);
    
// O11       // You might want to store phone number in Firestore separately
// O11       return const Right(null);
// O11     } on firebase_auth.FirebaseAuthException catch (e) {
// O11       return Left(Failure.fromFirebaseAuthException(e));
// O11     } catch (e) {
// O11       return Left(Failure(message: 'Registration failed. Please try again.'));
// O11     }
// O11   }

// O11   @override
// O11   Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
// O11     try {
// O11       await _firebaseAuth.sendPasswordResetEmail(email: email);
// O11       return const Right(null);
// O11     } on firebase_auth.FirebaseAuthException catch (e) {
// O11       return Left(Failure.fromFirebaseAuthException(e));
// O11     } catch (e) {
// O11       return Left(Failure(message: 'Password reset failed. Please try again.'));
// O11     }
// O11   }

// O11   @override
// O11   Future<Either<Failure, void>> sendEmailVerification() async {
// O11     try {
// O11       await _firebaseAuth.currentUser?.sendEmailVerification();
// O11       return const Right(null);
// O11     } on firebase_auth.FirebaseAuthException catch (e) {
// O11       return Left(Failure.fromFirebaseAuthException(e));
// O11     } catch (e) {
// O11       return Left(Failure(message: 'Failed to send verification email.'));
// O11     }
// O11   }

// O11   @override
// O11   Future<bool> isEmailVerified() async {
// O11     await _firebaseAuth.currentUser?.reload();
// O11     return _firebaseAuth.currentUser?.emailVerified ?? false;
// O11   }

// O11   @override
// O11   Future<Either<Failure, void>> signOut() async {
// O11     try {
// O11       await Future.wait([
// O11         _firebaseAuth.signOut(),
// O11         _googleSignIn.signOut(),
// O11       ]);
// O11       return const Right(null);
// O11     } catch (e) {
// O11       return Left(Failure(message: 'Logout failed. Please try again.'));
// O11     }
// O11   }

// O11   @override
// O11   Future<Either<Failure, void>> deleteAccount() async {
// O11     try {
// O11       await _firebaseAuth.currentUser?.delete();
// O11       return const Right(null);
// O11     } on firebase_auth.FirebaseAuthException catch (e) {
// O11       return Left(Failure.fromFirebaseAuthException(e));
// O11     } catch (e) {
// O11       return Left(Failure(message: 'Account deletion failed. Please try again.'));
// O11     }
// O11   }

// O11   @override
// O11   Future<Either<Failure, void>> updateUserProfile({
// O11     String? displayName,
// O11     String? photoUrl,
// O11   }) async {
// O11     try {
// O11       await _firebaseAuth.currentUser?.updateDisplayName(displayName);
// O11       if (photoUrl != null) {
// O11         await _firebaseAuth.currentUser?.updatePhotoURL(photoUrl);
// O11       }
// O11       return const Right(null);
// O11     } on firebase_auth.FirebaseAuthException catch (e) {
// O11       return Left(Failure.fromFirebaseAuthException(e));
// O11     } catch (e) {
// O11       return Left(Failure(message: 'Profile update failed. Please try again.'));
// O11     }
// O11   }

// O11   @override
// O11   Future<Either<Failure, String>> getIdToken() async {
// O11     try {
// O11       final token = await _firebaseAuth.currentUser?.getIdToken();
// O11       return token != null
// O11           ? Right(token)
// O11           : Left(Failure(message: 'Failed to get authentication token.'));
// O11     } catch (e) {
// O11       return Left(Failure(message: 'Failed to get authentication token.'));
// O11     }
// O11   }
// O11 }

// O11 extension on firebase_auth.User {
// O11   UserEntity toUserEntity() {
// O11     return UserEntity(
// O11       id: uid,
// O11       email: email,
// O11       name: displayName,
// O11       phoneNumber: phoneNumber,
// O11       photoUrl: photoURL,
// O11       emailVerified: emailVerified,
// O11     );
// O11   }
// O11 }