class AppSettings {
  final DateTime? roundStartDate;
  final DateTime? roundEndDate;
  final String? prizePool;

  AppSettings({
    this.roundStartDate,
    this.roundEndDate,
    this.prizePool,
  });

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      roundStartDate: map['roundStartDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['roundStartDate']) : null,
      roundEndDate: map['roundEndDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['roundEndDate']) : null,
      prizePool: map['prizePool'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (roundStartDate != null) 'roundStartDate': roundStartDate!.millisecondsSinceEpoch,
      if (roundEndDate != null) 'roundEndDate': roundEndDate!.millisecondsSinceEpoch,
      if (prizePool != null) 'prizePool': prizePool,
    };
  }
}
