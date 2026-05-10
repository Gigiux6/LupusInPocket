import 'player.dart';

enum RoomStatus { lobby, playing, finished }

enum GamePhase { notte, discussione, votazione }

class Room {
  final String id;
  final String hostId;
  final RoomStatus status;
  final GamePhase phase;
  final int? phaseEndTime;
  final List<String> turnOrder;
  final Map<String, Player> players;
  final String? lastKilledId;
  final String? winnerTeam;
  final String? werewolfVote;
  final String? guardianProtectId;
  final String? seerCheckId;
  final String? witchActionTargetId;
  final String? hunterActionTargetId;
  final String? mediumCheckId;
  final int discussionDuration;
  final int voteDuration;
  final int nightDuration;
  final int nightCount;
  final Map<PlayerRole, int> selectedRoles;
  final String? lastSystemMessage;
  final Map<String, dynamic>? deathAnnouncement;

  Room({
    required this.id,
    required this.hostId,
    required this.status,
    this.phase = GamePhase.discussione,
    this.phaseEndTime,
    required this.turnOrder,
    required this.players,
    this.lastKilledId,
    this.winnerTeam,
    this.werewolfVote,
    this.guardianProtectId,
    this.seerCheckId,
    this.witchActionTargetId,
    this.hunterActionTargetId,
    this.mediumCheckId,
    this.discussionDuration = 180,
    this.voteDuration = 30,
    this.nightDuration = 30,
    this.nightCount = 1,
    this.selectedRoles = const {
      PlayerRole.lupo: 1,
      PlayerRole.contadino: 4,
      PlayerRole.veggente: 1,
      PlayerRole.guardiano: 1,
    },
    this.lastSystemMessage,
    this.deathAnnouncement,
  });

  factory Room.fromMap(String id, Map<dynamic, dynamic> map) {
    Map<String, Player> players = {};
    if (map['players'] != null) {
      (map['players'] as Map<dynamic, dynamic>).forEach((k, v) {
        players[k.toString()] = Player.fromMap(k.toString(), v as Map<dynamic, dynamic>);
      });
    }

    Map<PlayerRole, int> roles = {};
    if (map['selectedRoles'] != null) {
      (map['selectedRoles'] as Map<dynamic, dynamic>).forEach((k, v) {
        try {
          final role = PlayerRole.values.firstWhere((e) => e.name == k.toString());
          roles[role] = (v as num).toInt();
        } catch (_) {}
      });
    }

    return Room(
      id: id,
      hostId: map['hostId'] ?? '',
      status: RoomStatus.values.firstWhere((e) => e.name == (map['status'] ?? 'lobby'), orElse: () => RoomStatus.lobby),
      phase: GamePhase.values.firstWhere((e) => e.name == (map['phase'] ?? 'discussione'), orElse: () => GamePhase.discussione),
      phaseEndTime: map['phaseEndTime'],
      turnOrder: List<String>.from(map['turnOrder'] ?? []),
      players: players,
      lastKilledId: map['lastKilledId'],
      winnerTeam: map['winnerTeam'],
      werewolfVote: map['werewolfVote'],
      guardianProtectId: map['guardianProtectId'],
      seerCheckId: map['seerCheckId'],
      witchActionTargetId: map['witchActionTargetId'],
      hunterActionTargetId: map['hunterActionTargetId'],
      mediumCheckId: map['mediumCheckId'],
      discussionDuration: map['discussionDuration'] ?? 180,
      voteDuration: map['voteDuration'] ?? 30,
      nightDuration: map['nightDuration'] ?? 30,
      nightCount: map['nightCount'] ?? 1,
      selectedRoles: roles,
      lastSystemMessage: map['lastSystemMessage'],
      deathAnnouncement: map['deathAnnouncement'] != null ? Map<String, dynamic>.from(map['deathAnnouncement'] as Map) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hostId': hostId,
      'status': status.name,
      'phase': phase.name,
      'phaseEndTime': phaseEndTime,
      'turnOrder': turnOrder,
      'players': players.map((k, v) => MapEntry(k, v.toMap())),
      'lastKilledId': lastKilledId,
      'winnerTeam': winnerTeam,
      'werewolfVote': werewolfVote,
      'guardianProtectId': guardianProtectId,
      'seerCheckId': seerCheckId,
      'witchActionTargetId': witchActionTargetId,
      'hunterActionTargetId': hunterActionTargetId,
      'mediumCheckId': mediumCheckId,
      'discussionDuration': discussionDuration,
      'voteDuration': voteDuration,
      'nightDuration': nightDuration,
      'nightCount': nightCount,
      'selectedRoles': selectedRoles.map((k, v) => MapEntry(k.name, v)),
      'lastSystemMessage': lastSystemMessage,
      'deathAnnouncement': deathAnnouncement,
    };
  }
}
