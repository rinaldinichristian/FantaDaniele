import 'package:flutter/material.dart';

class DailySession {
  final String id; // Solitamente la data, es. '2026-09-10'
  final bool isOpen;
  final TimeOfDay? actualArrivalTime;
  final String? winnerId;

  DailySession({
    required this.id,
    this.isOpen = true,
    this.actualArrivalTime,
    this.winnerId,
  });

  factory DailySession.fromMap(String id, Map<String, dynamic> map) {
    TimeOfDay? arrivalTime;
    if (map['arrivalHour'] != null && map['arrivalMinute'] != null) {
      arrivalTime = TimeOfDay(hour: map['arrivalHour'], minute: map['arrivalMinute']);
    }

    return DailySession(
      id: id,
      isOpen: map['isOpen'] ?? true,
      actualArrivalTime: arrivalTime,
      winnerId: map['winnerId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isOpen': isOpen,
      'arrivalHour': actualArrivalTime?.hour,
      'arrivalMinute': actualArrivalTime?.minute,
      'winnerId': winnerId,
    };
  }
}
