import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/room.dart';
import '../models/player.dart';
import '../models/message.dart';
import '../services/firebase_service.dart';
import 'package:audioplayers/audioplayers.dart';
import '../data/translations.dart';
import 'package:lupus_in_pocket/providers/user_provider.dart';

class GameProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();

  GameProvider() {
    _initAudio();
  }

  void _initAudio() {
    // Basic setup for web/mobile compatibility - aligned with GuessMe
  }

  Room? currentRoom;
  String? currentPlayerId;
  StreamSubscription<Room?>? _roomSubscription;
  StreamSubscription<List<Message>>? _messagesSubscription;
  List<Message> messages = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _isProcessingPhaseEnd = false;

  String _language = 'it';
  void setLanguage(String lang) {
    _language = lang;
  }

  Timer? _phaseTimer;
  int _remainingSeconds = 0;
  int get remainingSeconds => _remainingSeconds;

  String get formattedTime {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void listenToRoom(String roomId) {
    _roomSubscription?.cancel();
    _roomSubscription = _firebaseService.getRoomStream(roomId).listen((room) {
      if (room == null) {
        if (currentRoom != null) {
          _roomSubscription?.cancel();
          _messagesSubscription?.cancel();
          currentRoom = null;
          currentPlayerId = null;
          notifyListeners();
        }
      } else {
        bool phaseChanged = currentRoom?.phase != room.phase;
        currentRoom = room;
        if (phaseChanged) {
          _isProcessingPhaseEnd = false;
          _startLocalTimer();
        }
        notifyListeners();
      }
    });

    _messagesSubscription?.cancel();
    _messagesSubscription = _firebaseService.getMessagesStream(roomId).listen((msgs) {
      messages = msgs;
      notifyListeners();
    });
  }

  void _startLocalTimer() {
    _phaseTimer?.cancel();
    if (currentRoom?.phaseEndTime == null) return;

    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final diff = (currentRoom!.phaseEndTime! - now) ~/ 1000;
      
      if (diff <= 0) {
        _remainingSeconds = 0;
        timer.cancel();
        if (isHost) {
          _onPhaseEnd();
        } else {
          Future.delayed(const Duration(seconds: 5), () {
            if (currentRoom != null && currentRoom!.phaseEndTime != null) {
              final now = DateTime.now().millisecondsSinceEpoch;
              if (now > currentRoom!.phaseEndTime! + 5000) {
                final activePlayers = currentRoom!.players.values.where((p) => p.isAlive).toList();
                activePlayers.sort((a, b) => a.id.compareTo(b.id));
                if (activePlayers.isNotEmpty && activePlayers.first.id == currentPlayerId) {
                   _onPhaseEnd();
                }
              }
            }
          });
        }
      } else {
        _remainingSeconds = diff;
      }
      notifyListeners();
    });
  }

  Future<void> _onPhaseEnd() async {
    if (currentRoom == null || _isProcessingPhaseEnd) return;
    
    _isProcessingPhaseEnd = true;
    try {
      if (currentRoom!.phase == GamePhase.notte) {
        await _processNightResults();
      } else if (currentRoom!.phase == GamePhase.discussione) {
        await startPhase(GamePhase.votazione);
      } else if (currentRoom!.phase == GamePhase.votazione) {
        await _processDayResults();
      }
    } catch (e) {
      debugPrint("Error in _onPhaseEnd: $e");
      _isProcessingPhaseEnd = false; // Reset flag on error to allow retry
    }
  }

  Future<void> _processNightResults() async {
    if (!isHost || currentRoom == null) return;
    Map<String, int> wolfVotes = {};
    currentRoom!.players.forEach((id, player) {
      if (player.role == PlayerRole.lupo && player.isAlive && player.votedFor != null) {
        wolfVotes[player.votedFor!] = (wolfVotes[player.votedFor!] ?? 0) + 1;
      }
    });

    String? victimId;
    if (wolfVotes.isNotEmpty) {
      int maxVotes = -1;
      wolfVotes.forEach((id, count) {
        if (count > maxVotes) {
          maxVotes = count;
          victimId = id;
        }
      });
    }

    Set<String> protectedIds = {};
    for (var p in currentRoom!.players.values) {
      if (p.isAlive && p.role == PlayerRole.guardiano && p.votedFor != null) {
        protectedIds.add(p.votedFor!);
      }
    }

    if (victimId != null && protectedIds.contains(victimId)) {
      victimId = null;
    }

    if (victimId != null) {
      final victim = currentRoom!.players[victimId];
      if (victim?.role == PlayerRole.criceto_mannaro) {
        await _firebaseService.assignRoles(currentRoom!.id, {victimId!: PlayerRole.lupo});
        victimId = null;
      }
    }

    String? resurrectedId;
    for (var witch in currentRoom!.players.values.where((p) => p.role == PlayerRole.strega && p.isAlive)) {
      if (witch.votedFor != null && !witch.hasUsedPotion) {
        final target = currentRoom!.players[witch.votedFor!];
        if (target != null && !target.isAlive) {
           resurrectedId = target.id;
           await _firebaseService.resurrectPlayer(currentRoom!.id, target.id);
           await _firebaseService.updatePlayerLastAction(currentRoom!.id, witch.id, null, hasUsedPotion: true);
           await sendSystemMessage(AppTranslations.translate('msg_resurrected', _language, args: {'name': target.name}));
        }
      }
    }

    for (var guardiano in currentRoom!.players.values.where((p) => p.role == PlayerRole.guardiano && p.isAlive)) {
       await _firebaseService.updatePlayerLastAction(currentRoom!.id, guardiano.id, guardiano.votedFor);
    }

    Set<String> hunterVictimIds = {};
    for (var hunter in currentRoom!.players.values.where((p) => p.role == PlayerRole.cacciatore && p.isAlive)) {
      if (hunter.votedFor != null && !hunter.hasUsedBullet) {
        String targetId = hunter.votedFor!;
        if (!protectedIds.contains(targetId)) {
          hunterVictimIds.add(targetId);
          await _firebaseService.updateHunterBullet(currentRoom!.id, hunter.id, true);
        }
      }
    }

    // Mitomane logic - copy role if a target was selected
    final mitomanePlayers = currentRoom!.players.values.where((p) => p.role == PlayerRole.mitomane && p.isAlive).toList();
    for (var mitomane in mitomanePlayers) {
      if (mitomane.votedFor != null) {
        final target = currentRoom!.players[mitomane.votedFor!];
        if (target != null && target.role != null) {
           // Assign the target's role to the mitomane
           await _firebaseService.assignRoles(currentRoom!.id, {mitomane.id: target.role!});
        }
      }
    }

    Set<String> tonightDead = {};
    if (victimId != null) tonightDead.add(victimId!);
    for (var id in hunterVictimIds) tonightDead.add(id);

    List<Map<String, dynamic>> events = [];
    
    if (tonightDead.isNotEmpty) {
      List<String> names = tonightDead.map((id) => currentRoom!.players[id]?.name ?? 'Qualcuno').toList();
      String namesStr = names.join(" e ");
      events.add({'playerName': namesStr, 'cause': 'suspicious'});
      await sendSystemMessage(AppTranslations.translate('msg_suspicious_deaths', _language, args: {'names': namesStr}));
      for (var id in tonightDead) {
        await _firebaseService.killPlayer(currentRoom!.id, id);
      }
    } else {
      events.add({'playerName': null, 'cause': 'none_night'});
      await sendSystemMessage(AppTranslations.translate('msg_no_deaths', _language));
    }

    if (resurrectedId != null) {
      final res = currentRoom!.players[resurrectedId];
      events.add({'playerName': res?.name ?? 'Qualcuno', 'cause': 'resurrection'});
    }

    await _firebaseService.setDeathAnnouncement(currentRoom!.id, {'events': events});


    await checkWinConditions();
    if (currentRoom!.status != RoomStatus.finished) {
      await startPhase(GamePhase.discussione);
    }
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _messagesSubscription?.cancel();
    _phaseTimer?.cancel();
    _audioPlayer.dispose();
    _bgmPlayer.dispose();
    super.dispose();
  }

  void playLobbyMusic(double volume) async {
    if (volume <= 0) {
      if (_bgmPlayer.state == PlayerState.playing) {
        await _bgmPlayer.pause();
      }
      return;
    }

    if (_bgmPlayer.state == PlayerState.playing) {
      await _bgmPlayer.setVolume(volume * 0.4);
      return;
    }

    if (_bgmPlayer.state == PlayerState.paused) {
      await _bgmPlayer.resume();
      await _bgmPlayer.setVolume(volume * 0.4);
      return;
    }

    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.play(AssetSource('audio/lobby_music.mp3'), volume: volume * 0.4);
    } catch (e) {
      debugPrint('Error playing lobby music: $e');
    }
  }

  Future<void> playWhoosh(double volume) async {
    try {
      final gameProvider = this;
      // Disabilita il suono se siamo di notte per non rivelare i movimenti
      if (gameProvider.currentRoom?.phase != GamePhase.notte) {
        await _audioPlayer.play(AssetSource('audio/whoosh.mp3'), volume: volume);
      }
    } catch (e) {
      debugPrint('Error playing whoosh sound: $e');
    }
  }

  void stopLobbyMusic() async {
    await _bgmPlayer.stop();
  }

  void pauseLobbyMusic() async {
    if (_bgmPlayer.state == PlayerState.playing) {
      await _bgmPlayer.pause();
    }
  }

  void resumeLobbyMusic() async {
    if (_bgmPlayer.state == PlayerState.paused) {
      await _bgmPlayer.resume();
    }
  }

  void playSound(String path) async {
    try {
      await _audioPlayer.play(AssetSource(path.replaceFirst('assets/', '')));
    } catch (e) {
      debugPrint('Error playing sound $path: $e');
    }
  }

  Future<void> createRoom(String playerName, String uid, {String? avatarUrl}) async {
    _setLoading(true);
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    String roomId = String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    currentPlayerId = uid;
    Player host = Player(id: uid, name: playerName, avatarUrl: avatarUrl);
    Room room = Room(id: roomId, hostId: uid, status: RoomStatus.lobby, turnOrder: [uid], players: {uid: host});
    await _firebaseService.createRoom(room);
    listenToRoom(roomId);
    _setLoading(false);
  }

  Future<void> saveRoomId(String? roomId, UserProvider userProvider) async {
    await userProvider.setLastRoomId(roomId);
  }

  Future<bool> joinRoom(String roomId, String playerName, String uid, {String? avatarUrl}) async {
    _setLoading(true);
    currentPlayerId = uid;
    Player player = Player(id: uid, name: playerName, avatarUrl: avatarUrl);
    bool success = await _firebaseService.joinRoom(roomId, player);
    if (!success) {
      _setLoading(false);
      currentPlayerId = null;
      return false;
    }
    listenToRoom(roomId);
    _setLoading(false);
    return true;
  }

  Future<void> startGame() async {
    if (currentRoom == null) return;
    int totalPlayers = currentRoom!.players.length;
    int totalRoles = currentRoom!.selectedRoles.values.fold(0, (sum, count) => sum + count);
    if (totalPlayers != totalRoles) return;
    _setLoading(true);
    stopLobbyMusic();
    List<String> playerIds = currentRoom!.players.keys.toList();
    playerIds.shuffle();
    Map<String, PlayerRole> roles = {};
    int currentIndex = 0;
    currentRoom!.selectedRoles.forEach((role, count) {
      for (int i = 0; i < count; i++) {
        if (currentIndex < playerIds.length) {
          roles[playerIds[currentIndex]] = role;
          currentIndex++;
        }
      }
    });
    await _firebaseService.assignRoles(currentRoom!.id, roles);
    await _firebaseService.updateRoomStatus(currentRoom!.id, RoomStatus.playing);
    await startPhase(GamePhase.notte);
    _setLoading(false);
  }

  Future<void> updateRoleCount(PlayerRole role, int count) async {
    if (currentRoom == null || !isHost) return;
    if (count < 0) return;
    if (role == PlayerRole.massoni) count = count > 0 ? 2 : 0;
    if (role == PlayerRole.guardiano && count < 1) return;
    if (role == PlayerRole.veggente && count < 1) return;
    if (role == PlayerRole.lupo && count < 1) return;
    if (role != PlayerRole.lupo && role != PlayerRole.contadino && role != PlayerRole.massoni && count > 1) return;
    final newRoles = Map<PlayerRole, int>.from(currentRoom!.selectedRoles);
    if (count == 0 && role != PlayerRole.lupo && role != PlayerRole.contadino) {
      newRoles.remove(role);
    } else {
      newRoles[role] = count;
    }
    await _firebaseService.updateSelectedRoles(currentRoom!.id, newRoles);
  }

  Future<void> startPhase(GamePhase phase) async {
    if (currentRoom == null) return;
    int duration = 30;
    if (phase == GamePhase.discussione) duration = currentRoom!.discussionDuration;
    else if (phase == GamePhase.votazione) duration = currentRoom!.voteDuration;
    else if (phase == GamePhase.notte) duration = currentRoom!.nightDuration;
    int endTime = DateTime.now().millisecondsSinceEpoch + (duration * 1000);
    await _firebaseService.updatePhase(currentRoom!.id, phase, endTime: endTime);
    await _firebaseService.resetVotes(currentRoom!.id);
    if (phase == GamePhase.notte) {
      await _firebaseService.updateNightCount(currentRoom!.id, currentRoom!.nightCount + 1);
      await sendSystemMessage(AppTranslations.translate('msg_night_fall', _language));
    } else if (phase == GamePhase.discussione) {
      await sendSystemMessage(AppTranslations.translate('msg_day_break', _language));
    } else if (phase == GamePhase.votazione) {
      await sendSystemMessage(AppTranslations.translate('msg_vote_start', _language));
    }
  }

  Future<void> sendSystemMessage(String text) async {
    if (currentRoom == null) return;
    await _firebaseService.sendMessage(currentRoom!.id, Message(id: '', senderId: 'system', senderName: 'Game Master', text: text, timestamp: DateTime.now().millisecondsSinceEpoch));
  }

  Future<void> sendMessage(String text, {bool isWolfOnly = false, bool isMassoniOnly = false}) async {
    if (currentRoom == null || currentPlayerId == null) return;
    final player = currentRoom!.players[currentPlayerId];
    if (player == null || !player.isAlive) return;
    await _firebaseService.sendMessage(currentRoom!.id, Message(id: '', senderId: currentPlayerId!, senderName: player.name, text: text, timestamp: DateTime.now().millisecondsSinceEpoch, isWolfOnly: isWolfOnly, isMassoniOnly: isMassoniOnly));
  }

  Future<void> vote(String? targetId) async {
    if (currentRoom == null || currentPlayerId == null) return;
    final player = currentRoom!.players[currentPlayerId];
    if (player == null || !player.isAlive) return;
    if (currentRoom!.phase == GamePhase.votazione) {
      await _firebaseService.castVote(currentRoom!.id, currentPlayerId!, targetId);
    } else if (currentRoom!.phase == GamePhase.notte) {
      if (player.role == PlayerRole.lupo) await _firebaseService.setWerewolfVote(currentRoom!.id, currentPlayerId!, targetId);
      else if (player.role == PlayerRole.guardiano) {
        if (targetId == null || targetId == player.lastActionTargetId) return;
        await _firebaseService.setGuardianProtect(currentRoom!.id, currentPlayerId!, targetId);
      } else if (player.role == PlayerRole.mitomane) {
        if (targetId == null || currentRoom!.nightCount > 1) return;
        await _firebaseService.setMitomaneAction(currentRoom!.id, currentPlayerId!, targetId);
      } else if (player.role == PlayerRole.veggente) {
        if (targetId == null) return;
        await _firebaseService.setSeerCheck(currentRoom!.id, currentPlayerId!, targetId);
      } else if (player.role == PlayerRole.strega) {
        if (targetId == null || player.hasUsedPotion) return;
        await _firebaseService.setWitchAction(currentRoom!.id, currentPlayerId!, targetId);
      } else if (player.role == PlayerRole.cacciatore) {
        if (targetId == null || player.hasUsedBullet) return;
        await _firebaseService.setHunterAction(currentRoom!.id, currentPlayerId!, targetId);
      } else if (player.role == PlayerRole.medium) {
        if (targetId == null) return;
        await _firebaseService.setMediumCheck(currentRoom!.id, currentPlayerId!, targetId);
      }
    }
  }

  Future<void> checkWinConditions() async {
    if (currentRoom == null) return;
    if (currentRoom!.lastKilledId != null && currentRoom!.phase != GamePhase.notte) {
      final lastKilled = currentRoom!.players[currentRoom!.lastKilledId];
      if (lastKilled?.role == PlayerRole.jolly) {
         await _firebaseService.setWinnerTeam(currentRoom!.id, 'jolly');
         await sendSystemMessage(AppTranslations.translate('msg_jolly_win', _language));
         return;
      }
    }
    int lupi = currentRoom!.players.values.where((p) => p.isAlive && (p.role == PlayerRole.lupo || p.role == PlayerRole.indemoniato)).length;
    int buoni = currentRoom!.players.values.where((p) => p.isAlive && p.role != PlayerRole.lupo && p.role != PlayerRole.indemoniato).length;
    if (lupi == 0) {
      await _firebaseService.setWinnerTeam(currentRoom!.id, 'buoni');
      await sendSystemMessage(AppTranslations.translate('msg_buoni_win', _language));
    } else if (lupi >= buoni) {
      await _firebaseService.setWinnerTeam(currentRoom!.id, 'lupi');
      await sendSystemMessage(AppTranslations.translate('msg_lupi_win', _language));
    }
  }

  bool get isHost => currentRoom?.hostId == currentPlayerId;
  Player? get me => currentRoom?.players[currentPlayerId];

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> updateRoomDurations(int discussion, int vote, int night) async {
    if (currentRoom == null || !isHost) return;
    await _firebaseService.updateRoomDurations(currentRoom!.id, discussion, vote, night);
  }

  Future<void> returnToLobby() async {
    if (currentRoom == null) return;
    await _firebaseService.resetRoomForNewGame(currentRoom!.id);
  }

  Future<void> setInLobby(bool value) async {
    if (currentRoom == null || currentPlayerId == null) return;
    if (me?.inLobby == value) return;
    await _firebaseService.updatePlayerLobbyStatus(currentRoom!.id, currentPlayerId!, value);
  }

  Future<void> leaveRoom({String? name}) async {
    if (currentRoom == null || currentPlayerId == null) return;
    String roomId = currentRoom!.id;
    
    // Non cancelliamo più la stanza automaticamente se l'host esce.
    // L'host può rientrare o chiuderla esplicitamente.
    
    if (name != null && !isHost) {
      final text = AppTranslations.translate('player_left', _language, args: {'name': name});
      await sendSystemMessage(text);
      await _firebaseService.updateLastSystemMessage(roomId, text);
    }
    
    if (!isHost) {
      await _firebaseService.removePlayer(roomId, currentPlayerId!);
    }
    
    await exitToHome();
  }

  /// Torna alla home senza rimuovere il giocatore dal database (permette il rejoin)
  Future<void> exitToHome() async {
    _roomSubscription?.cancel();
    _messagesSubscription?.cancel();
    _phaseTimer?.cancel();
    currentRoom = null;
    currentPlayerId = null;
    notifyListeners();
  }

  /// Chiude definitivamente la stanza (solo per l'host)
  Future<void> closeRoom() async {
    if (currentRoom == null || !isHost) return;
    await _firebaseService.deleteRoom(currentRoom!.id);
    await exitToHome();
  }

  Future<void> _processDayResults() async {
    if (!isHost || currentRoom == null) return;
    Map<String, int> voteCounts = {};
    int abstainCount = 0;
    currentRoom!.players.forEach((id, player) {
      if (player.votedFor == 'abstain') abstainCount++;
      else if (player.votedFor != null) voteCounts[player.votedFor!] = (voteCounts[player.votedFor!] ?? 0) + 1;
    });
    if (voteCounts.isEmpty) {
        await _firebaseService.setDeathAnnouncement(currentRoom!.id, {
          'events': [{'playerName': null, 'cause': 'none_day'}]
        });
        await sendSystemMessage(AppTranslations.translate('msg_no_execution', _language));
    } else {
      int maxVotes = 0;
      voteCounts.forEach((id, count) { if (count > maxVotes) maxVotes = count; });
      List<String> topVotedIds = [];
      voteCounts.forEach((id, count) { if (count == maxVotes) topVotedIds.add(id); });
      if (abstainCount > maxVotes || (maxVotes == 0 && abstainCount == 0)) {
        await _firebaseService.setDeathAnnouncement(currentRoom!.id, {
          'events': [{'playerName': null, 'cause': 'none_day'}]
        });
        await sendSystemMessage(AppTranslations.translate('msg_no_execution', _language));
      } else if (topVotedIds.length > 1) {
        await _firebaseService.setDeathAnnouncement(currentRoom!.id, {
          'events': [{'playerName': null, 'cause': 'none_day'}]
        });
        await sendSystemMessage(AppTranslations.translate('msg_tie', _language));
      } else if (topVotedIds.length == 1) {
        String victimId = topVotedIds.first;
        final victim = currentRoom!.players[victimId];
        await _firebaseService.killPlayer(currentRoom!.id, victimId);
        await _firebaseService.setDeathAnnouncement(currentRoom!.id, {
          'events': [{'playerName': victim?.name ?? 'Qualcuno', 'cause': 'village'}]
        });
        await sendSystemMessage(AppTranslations.translate('msg_voted_out', _language, args: {'name': victim?.name ?? 'Qualcuno'}));
      }
    }
    await checkWinConditions();
    if (currentRoom!.status != RoomStatus.finished) {
      // Aspettiamo che l'animazione del rogo finisca (4s) + margine
      await Future.delayed(const Duration(milliseconds: 4500));
      await startPhase(GamePhase.notte);
    }
  }

  Future<void> clearDeathAnnouncement() async {
    if (currentRoom == null) return;
    await _firebaseService.setDeathAnnouncement(currentRoom!.id, null);
  }

  void _checkAllVoted() {
    if (currentRoom == null) return;
    final alivePlayers = currentRoom!.players.values.where((p) => p.isAlive).toList();
    
    bool allVoted = false;
    if (currentRoom!.phase == GamePhase.votazione) {
       allVoted = alivePlayers.every((p) => p.votedFor != null);
    } else if (currentRoom!.phase == GamePhase.notte) {
       // Di notte aspettiamo i ruoli attivi
       final activeRoles = alivePlayers.where((p) => 
         p.role == PlayerRole.lupo || 
         p.role == PlayerRole.guardiano ||
         p.role == PlayerRole.veggente ||
         p.role == PlayerRole.cacciatore ||
         p.role == PlayerRole.medium ||
         p.role == PlayerRole.strega ||
         (p.role == PlayerRole.mitomane && currentRoom!.nightCount == 1)
       );
       allVoted = activeRoles.every((p) => p.votedFor != null || (p.role == PlayerRole.strega && p.hasUsedPotion) || (p.role == PlayerRole.cacciatore && p.hasUsedBullet));
    }

    if (allVoted && alivePlayers.isNotEmpty) {
      // Delay estetico di 1 secondo prima di concludere la votazione
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (currentRoom != null && !_isProcessingPhaseEnd) {
           _onPhaseEnd();
        }
      });
    }
  }
}
