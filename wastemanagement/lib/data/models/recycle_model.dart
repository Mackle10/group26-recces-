import 'package:cloud_firestore/cloud_firestore.dart';

class RecyclableModel {
  final String? id;
  final String userId;
  final String type;
  final double quantity;
  final double price;
  final String status;
  final String? purchasedBy;
  final DateTime createdAt;
  final DateTime? purchasedAt;

  RecyclableModel({
    this.id,
    required this.userId,
    required this.type,
    required this.quantity,
    required this.price,
    required this.status,
    this.purchasedBy,
    required this.createdAt,
    this.purchasedAt,
  });

  factory RecyclableModel.fromMap(Map<String, dynamic> map) {
    return RecyclableModel(
      id: map['id'],
      userId: map['userId'],
      type: map['type'],
      quantity: map['quantity'].toDouble(),
      price: map['price'].toDouble(),
      status: map['status'],
      purchasedBy: map['purchasedBy'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      purchasedAt: map['purchasedAt'] != null ? (map['purchasedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'quantity': quantity,
      'price': price,
      'status': status,
      'purchasedBy': purchasedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'purchasedAt': purchasedAt != null ? Timestamp.fromDate(purchasedAt!) : null,
    };
  }
}
