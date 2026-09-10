import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Bet {
  final String id;
  final String userId;
  final String userName;
  final TimeOfDay time;
  final DateTime createdAt;

  Bet({
    required this.id,
    required this.userId,
    required this.userName,
    required this.time,
    required this.createdAt,
  });

  factory Bet.fromMap(String id, Map<String, dynamic> map) {
    return Bet(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Sconosciuto',
      time: TimeOfDay(
        hour: map['hour'] ?? 0,
        minute: map['minute'] ?? 0,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'hour': time.hour,
      'minute': time.minute,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
