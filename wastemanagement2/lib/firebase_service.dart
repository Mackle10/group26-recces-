import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User authentication
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<User?> registerWithEmailAndPassword(
      String email, String password, String name, String phone) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      
      // Save user info to Firestore
      await _firestore.collection('users').doc(result.user?.uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'address': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return result.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Waste pickup methods
  Future<void> schedulePickup(Map<String, dynamic> pickupData) async {
    await _firestore.collection('pickups').add({
      ...pickupData,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Recyclables methods
  Future<void> postRecyclable(Map<String, dynamic> recyclableData) async {
    await _firestore.collection('recyclables').add({
      ...recyclableData,
      'status': 'available',
      'postedAt': FieldValue.serverTimestamp(),
    });
  }

  // User data
  Future<Map<String, dynamic>> getUserData(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    return doc.data() as Map<String, dynamic>;
  }

  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }
}