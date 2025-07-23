import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wastemanagement/data/models/user_model.dart';

abstract class AuthRepository {
  Stream<User?> get user;

  User? get currentUser;

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String role,
  });

  Future<void> sendPasswordResetEmail(String email);
  Future<void> sendEmailVerification();
  Future<bool> isEmailVerified();

  Future<void> signOut();
  Future<void> deleteAccount();
  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
  });

  Future<String> getIdToken();
  Future<User?> getCurrentUser(); // <--- use Firebase User directly
}


class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  Stream<User?> get user => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<User?> getCurrentUser() async {
    return _firebaseAuth.currentUser;
  }

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String role,
  }) async {
    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await userCredential.user?.updateDisplayName(fullName);
    await userCredential.user?.reload();
    // Write user to Firestore with role
    final user = userCredential.user;
    if (user != null) {
      final userModel = UserModel(
        id: user.uid,
        name: fullName,
        email: email,
        phone: phoneNumber,
        address: '', // You may want to collect this in the form
        role: role,
        createdAt: DateTime.now(),
      );
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(userModel.toMap());
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> sendEmailVerification() async {
    await _firebaseAuth.currentUser?.sendEmailVerification();
  }

  @override
  Future<bool> isEmailVerified() async {
    await _firebaseAuth.currentUser?.reload();
    return _firebaseAuth.currentUser?.emailVerified ?? false;
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    await _firebaseAuth.currentUser?.delete();
  }

  @override
  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    await _firebaseAuth.currentUser?.updateDisplayName(displayName);
    await _firebaseAuth.currentUser?.updatePhotoURL(photoUrl);
    await _firebaseAuth.currentUser?.reload();
  }

  @override
  Future<String> getIdToken() async {
    return await _firebaseAuth.currentUser?.getIdToken() ?? '';
  }
}
