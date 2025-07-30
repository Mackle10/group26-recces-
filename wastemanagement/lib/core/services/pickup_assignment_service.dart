import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wastemanagement/data/models/pickup_history_model.dart';
import 'package:wastemanagement/core/services/notification_service.dart';

class PickupAssignmentService {
  static final PickupAssignmentService _instance = PickupAssignmentService._internal();
  factory PickupAssignmentService() => _instance;
  PickupAssignmentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // Collection references
  CollectionReference get _pickupHistoryCollection =>
      _firestore.collection('pickup_history');
  CollectionReference get _companiesCollection =>
      _firestore.collection('companies');
  CollectionReference get _usersCollection =>
      _firestore.collection('users');

  // Auto-assign pickup to nearest available company
  Future<void> assignPickupToCompany(String pickupId) async {
    try {
      // Get pickup details
      DocumentSnapshot pickupDoc = await _pickupHistoryCollection.doc(pickupId).get();
      if (!pickupDoc.exists) {
        throw Exception('Pickup not found');
      }

      final pickupData = pickupDoc.data() as Map<String, dynamic>;
      final pickupLocation = GeoPoint(
        pickupData['latitude'] ?? 0.0,
        pickupData['longitude'] ?? 0.0,
      );

      // Find nearest available company
      String? nearestCompanyId = await _findNearestCompany(pickupLocation);
      
      if (nearestCompanyId == null) {
        throw Exception('No available companies found');
      }

      // Update pickup with company assignment
      await _pickupHistoryCollection.doc(pickupId).update({
        'companyId': nearestCompanyId,
        'status': 'assigned',
        'assignedAt': FieldValue.serverTimestamp(),
      });

      // Get company details
      DocumentSnapshot companyDoc = await _companiesCollection.doc(nearestCompanyId).get();
      final companyData = companyDoc.data() as Map<String, dynamic>;

      // Update pickup with company name
      await _pickupHistoryCollection.doc(pickupId).update({
        'companyName': companyData['name'] ?? 'Unknown Company',
      });

      // Send notification to company
      await _notificationService.scheduleNotification(
        id: pickupId.hashCode,
        title: 'New Pickup Assignment!',
        body: 'You have been assigned a new ${pickupData['wasteType']} pickup',
        scheduledDate: DateTime.now().add(const Duration(seconds: 2)),
        payload: '{"type": "pickup_assigned", "pickupId": "$pickupId"}',
      );

      // Send notification to user
      await _notificationService.scheduleNotification(
        id: (pickupId + '_user').hashCode,
        title: 'Pickup Assigned!',
        body: 'Your pickup has been assigned to ${companyData['name']}',
        scheduledDate: DateTime.now().add(const Duration(seconds: 3)),
        payload: '{"type": "pickup_assigned_user", "pickupId": "$pickupId"}',
      );

    } catch (e) {
      throw Exception('Failed to assign pickup: $e');
    }
  }

  // Find nearest available company
  Future<String?> _findNearestCompany(GeoPoint pickupLocation) async {
    try {
      // Get all active companies
      QuerySnapshot companiesSnapshot = await _companiesCollection
          .where('status', isEqualTo: 'active')
          .where('isAvailable', isEqualTo: true)
          .get();

      if (companiesSnapshot.docs.isEmpty) {
        return null;
      }

      String? nearestCompanyId;
      double minDistance = double.infinity;

      for (var companyDoc in companiesSnapshot.docs) {
        final companyData = companyDoc.data() as Map<String, dynamic>;
        final companyLocation = companyData['location'] as GeoPoint?;

        if (companyLocation != null) {
          double distance = _calculateDistance(
            pickupLocation.latitude,
            pickupLocation.longitude,
            companyLocation.latitude,
            companyLocation.longitude,
          );

          if (distance < minDistance) {
            minDistance = distance;
            nearestCompanyId = companyDoc.id;
          }
        }
      }

      return nearestCompanyId;
    } catch (e) {
      throw Exception('Failed to find nearest company: $e');
    }
  }

  // Calculate distance between two points (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth radius in meters
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // Get real-time pickup assignments for a company
  Stream<List<Map<String, dynamic>>> getCompanyPickupAssignments(String companyId) {
    return _pickupHistoryCollection
        .where('companyId', isEqualTo: companyId)
        .where('status', whereIn: ['assigned', 'in_progress'])
        .orderBy('assignedAt', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> assignments = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Get user details
        DocumentSnapshot userDoc = await _usersCollection.doc(data['userId']).get();
        Map<String, dynamic> userData = {};
        if (userDoc.exists) {
          userData = userDoc.data() as Map<String, dynamic>;
        }

        assignments.add({
          'id': doc.id,
          'userId': data['userId'],
          'userName': userData['name'] ?? 'Unknown User',
          'userPhone': userData['phone'] ?? 'No Phone',
          'userEmail': userData['email'] ?? 'No Email',
          'wasteType': data['wasteType'] ?? 'General',
          'scheduledDate': data['scheduledDate'],
          'assignedAt': data['assignedAt'],
          'status': data['status'],
          'address': data['address'],
          'latitude': data['latitude'],
          'longitude': data['longitude'],
          'notes': data['notes'],
          'weight': data['weight'],
          'price': data['price'],
        });
      }
      
      return assignments;
    });
  }

  // Update pickup status (for company use)
  Future<void> updatePickupStatus(String pickupId, String status) async {
    try {
      Map<String, dynamic> updateData = {
        'status': status,
      };

      if (status == 'in_progress') {
        updateData['startedAt'] = FieldValue.serverTimestamp();
      } else if (status == 'completed') {
        updateData['completedDate'] = FieldValue.serverTimestamp();
      }

      await _pickupHistoryCollection.doc(pickupId).update(updateData);

      // Send notification to user about status update
      DocumentSnapshot pickupDoc = await _pickupHistoryCollection.doc(pickupId).get();
      final pickupData = pickupDoc.data() as Map<String, dynamic>;

      String notificationTitle = '';
      String notificationBody = '';

      switch (status) {
        case 'in_progress':
          notificationTitle = 'Pickup Started!';
          notificationBody = 'Your waste collection is now in progress';
          break;
        case 'completed':
          notificationTitle = 'Pickup Completed!';
          notificationBody = 'Your waste has been successfully collected';
          break;
        case 'cancelled':
          notificationTitle = 'Pickup Cancelled';
          notificationBody = 'Your pickup has been cancelled';
          break;
      }

      if (notificationTitle.isNotEmpty) {
        await _notificationService.scheduleNotification(
          id: (pickupId + '_status').hashCode,
          title: notificationTitle,
          body: notificationBody,
          scheduledDate: DateTime.now().add(const Duration(seconds: 2)),
          payload: '{"type": "pickup_status_update", "pickupId": "$pickupId", "status": "$status"}',
        );
      }

    } catch (e) {
      throw Exception('Failed to update pickup status: $e');
    }
  }

  // Get all pending pickups (for admin/system use)
  Stream<List<Map<String, dynamic>>> getPendingPickups() {
    return _pickupHistoryCollection
        .where('status', isEqualTo: 'pending')
        .orderBy('scheduledDate', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> pickups = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Get user details
        DocumentSnapshot userDoc = await _usersCollection.doc(data['userId']).get();
        Map<String, dynamic> userData = {};
        if (userDoc.exists) {
          userData = userDoc.data() as Map<String, dynamic>;
        }

        pickups.add({
          'id': doc.id,
          'userId': data['userId'],
          'userName': userData['name'] ?? 'Unknown User',
          'wasteType': data['wasteType'] ?? 'General',
          'scheduledDate': data['scheduledDate'],
          'address': data['address'],
          'latitude': data['latitude'],
          'longitude': data['longitude'],
          'status': data['status'],
        });
      }
      
      return pickups;
    });
  }

  // Register a company in the system
  Future<void> registerCompany({
    required String companyId,
    required String name,
    required String phone,
    required String email,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      await _companiesCollection.doc(companyId).set({
        'name': name,
        'phone': phone,
        'email': email,
        'location': GeoPoint(latitude, longitude),
        'address': address,
        'status': 'active',
        'isAvailable': true,
        'createdAt': FieldValue.serverTimestamp(),
        'totalPickups': 0,
        'rating': 5.0,
      });
    } catch (e) {
      throw Exception('Failed to register company: $e');
    }
  }

  // Update company availability
  Future<void> updateCompanyAvailability(String companyId, bool isAvailable) async {
    try {
      await _companiesCollection.doc(companyId).update({
        'isAvailable': isAvailable,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update company availability: $e');
    }
  }

  // Get company statistics
  Future<Map<String, dynamic>> getCompanyStatistics(String companyId) async {
    try {
      // Get completed pickups count
      QuerySnapshot completedPickups = await _pickupHistoryCollection
          .where('companyId', isEqualTo: companyId)
          .where('status', isEqualTo: 'completed')
          .get();

      // Get in-progress pickups count
      QuerySnapshot inProgressPickups = await _pickupHistoryCollection
          .where('companyId', isEqualTo: companyId)
          .where('status', isEqualTo: 'in_progress')
          .get();

      // Get assigned pickups count
      QuerySnapshot assignedPickups = await _pickupHistoryCollection
          .where('companyId', isEqualTo: companyId)
          .where('status', isEqualTo: 'assigned')
          .get();

      // Calculate total earnings
      double totalEarnings = 0.0;
      for (var doc in completedPickups.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalEarnings += (data['price'] ?? 0.0).toDouble();
      }

      return {
        'totalPickups': completedPickups.docs.length,
        'inProgressPickups': inProgressPickups.docs.length,
        'assignedPickups': assignedPickups.docs.length,
        'totalEarnings': totalEarnings,
        'completionRate': completedPickups.docs.length > 0 
            ? (completedPickups.docs.length / (completedPickups.docs.length + assignedPickups.docs.length + inProgressPickups.docs.length)) * 100
            : 0.0,
      };
    } catch (e) {
      throw Exception('Failed to get company statistics: $e');
    }
  }
}