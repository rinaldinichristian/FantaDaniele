class AppUser {
  final String id;
  final String name;
  final String? avatarUrl;
  final int points;
  final int streak;

  AppUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.points = 0,
    this.streak = 0,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    return AppUser(
      id: id,
      name: map['name'] ?? '',
      avatarUrl: map['avatarUrl'],
      points: map['points']?.toInt() ?? 0,
      streak: map['streak']?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'avatarUrl': avatarUrl,
      'points': points,
      'streak': streak,
    };
  }
}
