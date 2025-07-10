import 'package:cloud_firestore/cloud_firestore.dart';

class PickupModel {
  final String? id;
  final String userId;
  final String? companyId;
  final String type;
  final String status;
  final GeoPoint location;
  final DateTime scheduledDate;
  final DateTime? completedAt;

  PickupModel({
    this.id,
    required this.userId,
    this.companyId,
    required this.type,
    required this.status,
    required this.location,
    required this.scheduledDate,
    this.completedAt,
  });

  factory PickupModel.fromMap(Map<String, dynamic> map) {
    return PickupModel(
      id: map['id'],
      userId: map['userId'],
      companyId: map['companyId'],
      type: map['type'],
      status: map['status'],
      location: map['location'],
      scheduledDate: (map['scheduledDate'] as Timestamp).toDate(),
      completedAt: map['completedAt'] != null ? (map['completedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'companyId': companyId,
      'type': type,
      'status': status,
      'location': location,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }
}