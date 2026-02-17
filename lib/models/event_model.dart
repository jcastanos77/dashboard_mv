import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final DateTime date;
  final String type;
  final String clientName;
  final String location;
  final double totalPrice;
  final double paidAmount;
  final String resourceType;

  EventModel({
    required this.id,
    required this.date,
    required this.type,
    required this.clientName,
    required this.location,
    required this.totalPrice,
    required this.paidAmount,
    required this.resourceType
  });

  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    return EventModel(
      id: id,
      date: (map['date'] as Timestamp).toDate(),
      type: map['type'],
      clientName: map['clientName'],
      location: map['location'],
      totalPrice: (map['totalPrice'] as num).toDouble(),
      paidAmount: (map['paidAmount'] as num).toDouble(),
      resourceType:  map['resourceType'],

    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'type': type,
      'clientName': clientName,
      'location': location,
      'totalPrice': totalPrice,
      'paidAmount': paidAmount,
      'resourceType': resourceType,
    };
  }
}
