// O11 import 'package:cloud_firestore/cloud_firestore.dart';
// O11 import 'package:wastemanagement/features/auth/data/models/user_model.dart';
// O11 import 'package:wastemanagement/features/company/data/models/company_model.dart';
// O11 import 'package:wastemanagement/features/pickup/data/models/pickup_model.dart';
// O11 import 'package:wastemanagement/features/recyclables/data/models/recyclable_model.dart';

// O11 abstract class FirebaseDataSource {
// O11   // User Operations
// O11   Future<void> createUser(UserModel user);
// O11   Future<UserModel> getUser(String userId);

// O11   // Company Operations
// O11   Future<void> createCompany(CompanyModel company);
// O11   Future<CompanyModel> getCompany(String companyId);

// O11   // Pickup Operations
// O11   Future<String> schedulePickup(PickupModel pickup);
// O11   Future<void> updatePickupStatus(String pickupId, String status);

// O11   // Recyclable Operations
// O11   Future<String> postRecyclable(RecyclableModel recyclable);
// O11   Future<void> updateRecyclableStatus(String recyclableId, String status);
// O11 }

// O11 class FirebaseDataSourceImpl implements FirebaseDataSource {
// O11   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// O11   @override
// O11   Future<void> createUser(UserModel user) async {
// O11     await _firestore.collection('users').doc(user.id).set(user.toMap());
// O11   }

// O11   @override
// O11   Future<UserModel> getUser(String userId) async {
// O11     final doc = await _firestore.collection('users').doc(userId).get();
// O11     return UserModel.fromMap(doc.data()!);
// O11   }

// O11   @override
// O11   Future<void> createCompany(CompanyModel company) async {
// O11     await _firestore.collection('companies').doc(company.id).set(company.toMap());
// O11   }

// O11   @override
// O11   Future<CompanyModel> getCompany(String companyId) async {
// O11     final doc = await _firestore.collection('companies').doc(companyId).get();
// O11     return CompanyModel.fromMap(doc.data()!);
// O11   }

// O11   @override
// O11   Future<String> schedulePickup(PickupModel pickup) async {
// O11     final docRef = await _firestore.collection('pickups').add(pickup.toMap());
// O11     return docRef.id;
// O11   }

// O11   @override
// O11   Future<void> updatePickupStatus(String pickupId, String status) async {
// O11     await _firestore.collection('pickups').doc(pickupId).update({'status': status});
// O11   }

// O11   @override
// O11   Future<String> postRecyclable(RecyclableModel recyclable) async {
// O11     final docRef = await _firestore.collection('recyclables').add(recyclable.toMap());
// O11     return docRef.id;
// O11   }

// O11   @override
// O11   Future<void> updateRecyclableStatus(String recyclableId, String status) async {
// O11     await _firestore.collection('recyclables').doc(recyclableId).update({'status': status});
// O11   }
// O11 }