class AppUser {
  final String id;
  final String name;
  final String? avatarUrl;
  final int points;
  final int streak;
  final bool isAdmin;
  final bool isDaniele;
  final String? fcmToken;

  AppUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.points = 0,
    this.streak = 0,
    this.isAdmin = false,
    this.isDaniele = false,
    this.fcmToken,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    return AppUser(
      id: id,
      name: map['name'] ?? '',
      avatarUrl: map['avatarUrl'],
      points: map['points']?.toInt() ?? 0,
      streak: map['streak']?.toInt() ?? 0,
      isAdmin: map['isAdmin'] ?? false,
      isDaniele: map['isDaniele'] ?? false,
      fcmToken: map['fcmToken'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'avatarUrl': avatarUrl,
      'points': points,
      'streak': streak,
      'isAdmin': isAdmin,
      'isDaniele': isDaniele,
      'fcmToken': fcmToken,
    };
  }
}
