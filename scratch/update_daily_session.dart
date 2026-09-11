import 'dart:io';

void main() {
  final file = File('lib/models/daily_session.dart');
  final content = '''
import 'package:flutter/material.dart';

class DailySession {
  final String id;
  final bool isOpen;
  final TimeOfDay? actualArrivalTime;
  final String? winnerId;
  final bool danieleWon;
  final String? proofImageUrl;

  DailySession({
    required this.id,
    this.isOpen = true,
    this.actualArrivalTime,
    this.winnerId,
    this.danieleWon = false,
    this.proofImageUrl,
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
      danieleWon: map['danieleWon'] ?? false,
      proofImageUrl: map['proofImageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isOpen': isOpen,
      'arrivalHour': actualArrivalTime?.hour,
      'arrivalMinute': actualArrivalTime?.minute,
      'winnerId': winnerId,
      'danieleWon': danieleWon,
      'proofImageUrl': proofImageUrl,
    };
  }
}
''';
  file.writeAsStringSync(content);
}
