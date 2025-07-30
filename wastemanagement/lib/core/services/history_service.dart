import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wastemanagement/data/models/pickup_history_model.dart';

class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get _pickupHistoryCollection =>
      _firestore.collection('pickup_history');

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Create a new pickup history entry
  Future<String> createPickupHistory(PickupHistoryModel pickup) async {
    try {
      DocumentReference docRef = await _pickupHistoryCollection.add(pickup.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create pickup history: $e');
    }
  }

  // Get pickup history for current user
  Stream<List<PickupHistoryModel>> getUserPickupHistory() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _pickupHistoryCollection
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('scheduledDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PickupHistoryModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get pickup history by status
  Stream<List<PickupHistoryModel>> getPickupHistoryByStatus(String status) {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _pickupHistoryCollection
        .where('userId', isEqualTo: _currentUserId)
        .where('status', isEqualTo: status)
        .orderBy('scheduledDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PickupHistoryModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get pickup history for a date range
  Stream<List<PickupHistoryModel>> getPickupHistoryByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _pickupHistoryCollection
        .where('userId', isEqualTo: _currentUserId)
        .where('scheduledDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('scheduledDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('scheduledDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PickupHistoryModel.fromFirestore(doc))
          .toList();
    });
  }

  // Update pickup status
  Future<void> updatePickupStatus(String pickupId, String status) async {
    try {
      await _pickupHistoryCollection.doc(pickupId).update({
        'status': status,
        if (status == 'completed') 'completedDate': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update pickup status: $e');
    }
  }

  // Update pickup with company information
  Future<void> updatePickupWithCompany(
    String pickupId,
    String companyId,
    String companyName,
  ) async {
    try {
      await _pickupHistoryCollection.doc(pickupId).update({
        'companyId': companyId,
        'companyName': companyName,
        'status': 'in_progress',
      });
    } catch (e) {
      throw Exception('Failed to update pickup with company: $e');
    }
  }

  // Add weight and price to completed pickup
  Future<void> updatePickupCompletion(
    String pickupId,
    double weight,
    double price,
  ) async {
    try {
      await _pickupHistoryCollection.doc(pickupId).update({
        'weight': weight,
        'price': price,
        'status': 'completed',
        'completedDate': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update pickup completion: $e');
    }
  }

  // Cancel pickup
  Future<void> cancelPickup(String pickupId, String reason) async {
    try {
      await _pickupHistoryCollection.doc(pickupId).update({
        'status': 'cancelled',
        'notes': reason,
      });
    } catch (e) {
      throw Exception('Failed to cancel pickup: $e');
    }
  }

  // Get pickup statistics
  Future<Map<String, dynamic>> getPickupStatistics() async {
    if (_currentUserId == null) {
      return {};
    }

    try {
      // Get all pickups for the user
      QuerySnapshot snapshot = await _pickupHistoryCollection
          .where('userId', isEqualTo: _currentUserId)
          .get();

      List<PickupHistoryModel> pickups = snapshot.docs
          .map((doc) => PickupHistoryModel.fromFirestore(doc))
          .toList();

      // Calculate statistics
      int totalPickups = pickups.length;
      int completedPickups = pickups.where((p) => p.isCompleted).length;
      int pendingPickups = pickups.where((p) => p.isPending).length;
      int cancelledPickups = pickups.where((p) => p.isCancelled).length;

      double totalWeight = pickups
          .where((p) => p.weight != null)
          .fold(0.0, (sum, p) => sum + p.weight!);

      double totalEarnings = pickups
          .where((p) => p.price != null)
          .fold(0.0, (sum, p) => sum + p.price!);

      // Get waste type breakdown
      Map<String, int> wasteTypeBreakdown = {};
      for (var pickup in pickups) {
        wasteTypeBreakdown[pickup.wasteType] =
            (wasteTypeBreakdown[pickup.wasteType] ?? 0) + 1;
      }

      // Get monthly statistics (last 12 months)
      DateTime now = DateTime.now();
      DateTime twelveMonthsAgo = DateTime(now.year - 1, now.month, now.day);
      
      List<PickupHistoryModel> recentPickups = pickups
          .where((p) => p.scheduledDate.isAfter(twelveMonthsAgo))
          .toList();

      Map<String, int> monthlyPickups = {};
      for (var pickup in recentPickups) {
        String monthKey = '${pickup.scheduledDate.year}-${pickup.scheduledDate.month.toString().padLeft(2, '0')}';
        monthlyPickups[monthKey] = (monthlyPickups[monthKey] ?? 0) + 1;
      }

      return {
        'totalPickups': totalPickups,
        'completedPickups': completedPickups,
        'pendingPickups': pendingPickups,
        'cancelledPickups': cancelledPickups,
        'totalWeight': totalWeight,
        'totalEarnings': totalEarnings,
        'wasteTypeBreakdown': wasteTypeBreakdown,
        'monthlyPickups': monthlyPickups,
        'completionRate': totalPickups > 0 ? (completedPickups / totalPickups * 100) : 0.0,
      };
    } catch (e) {
      throw Exception('Failed to get pickup statistics: $e');
    }
  }

  // Get single pickup by ID
  Future<PickupHistoryModel?> getPickupById(String pickupId) async {
    try {
      DocumentSnapshot doc = await _pickupHistoryCollection.doc(pickupId).get();
      if (doc.exists) {
        return PickupHistoryModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get pickup: $e');
    }
  }

  // Delete pickup (admin only)
  Future<void> deletePickup(String pickupId) async {
    try {
      await _pickupHistoryCollection.doc(pickupId).delete();
    } catch (e) {
      throw Exception('Failed to delete pickup: $e');
    }
  }
}