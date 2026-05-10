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
  final String? medicProtectId;
  final String? seerCheckId;
  final String? witchActionTargetId;
  final String? hunterActionTargetId;
  final String? mediumCheckId;
  final int discussionDuration;
  final int voteDuration;
  final int nightDuration;
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
    this.medicProtectId,
    this.seerCheckId,
    this.witchActionTargetId,
    this.hunterActionTargetId,
    this.mediumCheckId,
    this.discussionDuration = 180,
    this.voteDuration = 30,
    this.nightDuration = 30,
    this.selectedRoles = const {
      PlayerRole.lupo: 1,
      PlayerRole.veggente: 1,
      PlayerRole.medico: 1,
      PlayerRole.contadino: 1,
    },
    this.lastSystemMessage,
    this.deathAnnouncement,
  });

  factory Room.fromMap(String id, Map<dynamic, dynamic> map) {
    var statusStr = map['status'] ?? 'lobby';
    var phaseStr = map['phase'] ?? 'discussione';
    
    var playersMap = map['players'] as Map<dynamic, dynamic>? ?? {};
    Map<String, Player> players = {};
    playersMap.forEach((key, value) {
      if (value != null) {
        players[key.toString()] = Player.fromMap(key.toString(), value as Map<dynamic, dynamic>);
      }
    });

    var rolesMapRaw = map['selectedRoles'] as Map<dynamic, dynamic>? ?? {};
    Map<PlayerRole, int> selectedRoles = {};
    rolesMapRaw.forEach((key, value) {
      try {
        final role = PlayerRole.values.firstWhere((e) => e.name == key.toString());
        selectedRoles[role] = (value as num).toInt();
      } catch (_) {}
    });
    
    // Ensure default roles if empty
    if (selectedRoles.isEmpty) {
      selectedRoles = {
        PlayerRole.lupo: 1,
        PlayerRole.veggente: 1,
        PlayerRole.medico: 1,
        PlayerRole.contadino: 1,
      };
    }

    return Room(
      id: id,
      hostId: map['hostId'] ?? '',
      status: RoomStatus.values.firstWhere((e) => e.name == statusStr, orElse: () => RoomStatus.lobby),
      phase: GamePhase.values.firstWhere((e) => e.name == phaseStr, orElse: () => GamePhase.discussione),
      phaseEndTime: map['phaseEndTime'],
      turnOrder: map['turnOrder'] != null ? List<String>.from(map['turnOrder'] as List<dynamic>) : [],
      players: players,
      lastKilledId: map['lastKilledId'],
      winnerTeam: map['winnerTeam'],
      werewolfVote: map['werewolfVote'],
      medicProtectId: map['medicProtectId'],
      seerCheckId: map['seerCheckId'],
      witchActionTargetId: map['witchActionTargetId'],
      hunterActionTargetId: map['hunterActionTargetId'],
      mediumCheckId: map['mediumCheckId'],
      discussionDuration: map['discussionDuration'] ?? 180,
      voteDuration: map['voteDuration'] ?? 30,
      nightDuration: map['nightDuration'] ?? 30,
      selectedRoles: selectedRoles,
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
      'players': players.map((key, value) => MapEntry(key, value.toMap())),
      'lastKilledId': lastKilledId,
      'winnerTeam': winnerTeam,
      'werewolfVote': werewolfVote,
      'medicProtectId': medicProtectId,
      'seerCheckId': seerCheckId,
      'witchActionTargetId': witchActionTargetId,
      'hunterActionTargetId': hunterActionTargetId,
      'mediumCheckId': mediumCheckId,
      'discussionDuration': discussionDuration,
      'voteDuration': voteDuration,
      'nightDuration': nightDuration,
      'selectedRoles': selectedRoles.map((key, value) => MapEntry(key.name, value)),
      'lastSystemMessage': lastSystemMessage,
      'deathAnnouncement': deathAnnouncement,
    };
  }
}
