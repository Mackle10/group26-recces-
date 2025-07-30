import 'package:cloud_firestore/cloud_firestore.dart';

class PickupHistoryModel {
  final String id;
  final String userId;
  final String wasteType;
  final String status;
  final DateTime scheduledDate;
  final DateTime? completedDate;
  final String? companyId;
  final String? companyName;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? notes;
  final double? weight;
  final double? price;
  final List<String>? imageUrls;

  PickupHistoryModel({
    required this.id,
    required this.userId,
    required this.wasteType,
    required this.status,
    required this.scheduledDate,
    this.completedDate,
    this.companyId,
    this.companyName,
    this.latitude,
    this.longitude,
    this.address,
    this.notes,
    this.weight,
    this.price,
    this.imageUrls,
  });

  factory PickupHistoryModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PickupHistoryModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      wasteType: data['wasteType'] ?? '',
      status: data['status'] ?? 'pending',
      scheduledDate: (data['scheduledDate'] as Timestamp).toDate(),
      completedDate: data['completedDate'] != null
          ? (data['completedDate'] as Timestamp).toDate()
          : null,
      companyId: data['companyId'],
      companyName: data['companyName'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      address: data['address'],
      notes: data['notes'],
      weight: data['weight']?.toDouble(),
      price: data['price']?.toDouble(),
      imageUrls: data['imageUrls'] != null
          ? List<String>.from(data['imageUrls'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'wasteType': wasteType,
      'status': status,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'completedDate': completedDate != null
          ? Timestamp.fromDate(completedDate!)
          : null,
      'companyId': companyId,
      'companyName': companyName,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'notes': notes,
      'weight': weight,
      'price': price,
      'imageUrls': imageUrls,
    };
  }

  PickupHistoryModel copyWith({
    String? id,
    String? userId,
    String? wasteType,
    String? status,
    DateTime? scheduledDate,
    DateTime? completedDate,
    String? companyId,
    String? companyName,
    double? latitude,
    double? longitude,
    String? address,
    String? notes,
    double? weight,
    double? price,
    List<String>? imageUrls,
  }) {
    return PickupHistoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      wasteType: wasteType ?? this.wasteType,
      status: status ?? this.status,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completedDate: completedDate ?? this.completedDate,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      weight: weight ?? this.weight,
      price: price ?? this.price,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }

  // Helper methods
  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  String get wasteTypeDisplayName {
    switch (wasteType.toLowerCase()) {
      case 'general':
        return 'General Waste';
      case 'recyclable':
        return 'Recyclable';
      case 'hazardous':
        return 'Hazardous Waste';
      case 'organic':
        return 'Organic Waste';
      case 'electronic':
        return 'Electronic Waste';
      default:
        return wasteType;
    }
  }
}
