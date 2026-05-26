class UserModel {
  final String uid;
  final String name;
  final String avatarUrl;
  final int gamesWon;
  final String email;

  UserModel({
    required this.uid,
    required this.name,
    required this.avatarUrl,
    this.gamesWon = 0,
    this.email = '',
  });

  factory UserModel.fromMap(String uid, Map<dynamic, dynamic> map) {
    return UserModel(
      uid: uid,
      name: map['username'] ?? map['name'] ?? '',
      avatarUrl: map['photoUrl'] ?? map['avatarUrl'] ?? '',
      gamesWon: map['gamesWon'] ?? 0,
      email: map['email'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': name,
      'photoUrl': avatarUrl,
      'gamesWon': gamesWon,
      'email': email,
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? avatarUrl,
    int? gamesWon,
    String? email,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gamesWon: gamesWon ?? this.gamesWon,
      email: email ?? this.email,
    );
  }
}
