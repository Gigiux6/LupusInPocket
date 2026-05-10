enum PlayerRole { lupo, contadino, veggente, medico, massoni, medium, criceto_mannaro, jolly, strega, cacciatore, indemoniato }

class Player {
  final String id;
  final String name;
  final PlayerRole? role;
  final bool isAlive;
  final String? votedFor;
  final String? avatarUrl;
  final String? lastActionTargetId;
  final bool hasUsedPotion;
  final bool inLobby;

  Player({
    required this.id,
    required this.name,
    this.role,
    this.isAlive = true,
    this.votedFor,
    this.avatarUrl,
    this.lastActionTargetId,
    this.hasUsedPotion = false,
    this.hasUsedBullet = false,
    this.inLobby = false,
  });

  final bool hasUsedBullet;

  factory Player.fromMap(String id, Map<dynamic, dynamic> map) {
    return Player(
      id: id,
      name: map['name'] ?? '',
      role: map['role'] != null ? PlayerRole.values.firstWhere((e) => e.name == map['role']) : null,
      isAlive: map['isAlive'] ?? true,
      votedFor: map['votedFor'],
      avatarUrl: map['avatarUrl'],
      lastActionTargetId: map['lastActionTargetId'],
      hasUsedPotion: map['hasUsedPotion'] ?? false,
      hasUsedBullet: map['hasUsedBullet'] ?? false,
      inLobby: map['inLobby'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role?.name,
      'isAlive': isAlive,
      'votedFor': votedFor,
      'avatarUrl': avatarUrl,
      'lastActionTargetId': lastActionTargetId,
      'hasUsedPotion': hasUsedPotion,
      'hasUsedBullet': hasUsedBullet,
      'inLobby': inLobby,
    };
  }

  Player copyWith({
    String? id,
    String? name,
    PlayerRole? role,
    bool? isAlive,
    String? votedFor,
    String? avatarUrl,
    String? lastActionTargetId,
    bool? hasUsedPotion,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      isAlive: isAlive ?? this.isAlive,
      votedFor: votedFor ?? this.votedFor,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastActionTargetId: lastActionTargetId ?? this.lastActionTargetId,
      hasUsedPotion: hasUsedPotion ?? this.hasUsedPotion,
      inLobby: inLobby ?? this.inLobby,
    );
  }
}
