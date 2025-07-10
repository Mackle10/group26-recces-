import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final List<String> serviceAreas;
  final double rating;

  CompanyModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.serviceAreas,
    required this.rating,
  });

  factory CompanyModel.fromMap(Map<String, dynamic> map) {
    return CompanyModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      serviceAreas: List<String>.from(map['serviceAreas']),
      rating: map['rating'].toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'serviceAreas': serviceAreas,
      'rating': rating,
    };
  }
}