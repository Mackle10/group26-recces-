import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wastemanagement2/firebase_service.dart';

class AppAuthProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  User? _user;

  User? get user => _user;

  AppAuthProvider() {
    _init();
  }

  void _init() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<bool> login(String email, String password) async {
    try {
      _user = await _firebaseService.signInWithEmailAndPassword(email, password);
      notifyListeners();
      return _user != null;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> register(
      String email, String password, String name, String phone) async {
    try {
      _user = await _firebaseService.registerWithEmailAndPassword(
          email, password, name, phone);
      notifyListeners();
      return _user != null;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<void> logout() async {
    await _firebaseService.signOut();
    _user = null;
    notifyListeners();
  }
}