import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wastemanagement/data/models/user_model.dart';
import 'package:wastemanagement/data/models/company_model.dart';
import 'package:wastemanagement/data/models/pickup_model.dart';
import 'package:wastemanagement/data/models/recycle_model.dart';

abstract class FirebaseDataSource {
  // User Operations
  Future<void> createUser(UserModel user);
  Future<UserModel> getUser(String userId);

  // Company Operations
  Future<void> createCompany(CompanyModel company);
  Future<CompanyModel> getCompany(String companyId);

  // Pickup Operations
  Future<String> schedulePickup(PickupModel pickup);
  Future<void> updatePickupStatus(String pickupId, String status);

  // Recyclable Operations
  Future<String> postRecyclable(RecyclableModel recyclable);
  Future<void> updateRecyclableStatus(String recyclableId, String status);
}

class FirebaseDataSourceImpl implements FirebaseDataSource {
final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  @override
  Future<void> createUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set(user.toMap());
  }

  @override
  Future<UserModel> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return UserModel.fromMap(doc.data()!);
  }

  @override
  Future<void> createCompany(CompanyModel company) async {
    await _firestore.collection('companies').doc(company.id).set(company.toMap());
  }

  @override
  Future<CompanyModel> getCompany(String companyId) async {
    final doc = await _firestore.collection('companies').doc(companyId).get();
    return CompanyModel.fromMap(doc.data()!);
  }

  @override
  Future<String> schedulePickup(PickupModel pickup) async {
    final docRef = await _firestore.collection('pickups').add(pickup.toMap());
    return docRef.id;
  }

  @override
  Future<void> updatePickupStatus(String pickupId, String status) async {
    await _firestore.collection('pickups').doc(pickupId).update({'status': status});
  }

  @override
  Future<String> postRecyclable(RecyclableModel recyclable) async {
    final docRef = await _firestore.collection('recyclables').add(recyclable.toMap());
    return docRef.id;
  }

  @override
  Future<void> updateRecyclableStatus(String recyclableId, String status) async {
    await _firestore.collection('recyclables').doc(recyclableId).update({'status': status});
  }
}