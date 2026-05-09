import 'package:firebase_database/firebase_database.dart';
import '../models/room.dart';
import '../models/player.dart';
import '../models/message.dart';

class FirebaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Stream<Room?> getRoomStream(String roomId) {
    return _db.child('rooms/$roomId').onValue.map((event) {
      if (event.snapshot.value != null) {
        return Room.fromMap(roomId, event.snapshot.value as Map<dynamic, dynamic>);
      }
      return null;
    });
  }

  Stream<List<Message>> getMessagesStream(String roomId) {
    return _db.child('rooms/$roomId/messages').onValue.map((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> map = event.snapshot.value as Map<dynamic, dynamic>;
        List<Message> messages = [];
        map.forEach((key, value) {
          messages.add(Message.fromMap(key.toString(), value as Map<dynamic, dynamic>));
        });
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        return messages;
      }
      return [];
    });
  }

  Future<void> createRoom(Room room) async {
    await _db.child('rooms/${room.id}').set(room.toMap());
  }

  Future<bool> joinRoom(String roomId, Player player) async {
    final roomSnapshot = await _db.child('rooms/$roomId').get();
    if (!roomSnapshot.exists || roomSnapshot.child('hostId').value == null) {
      return false;
    }

    await _db.child('rooms/$roomId/players/${player.id}').set(player.toMap());
    
    final snapshot = await _db.child('rooms/$roomId/turnOrder').get();
    List<String> turnOrder = [];
    if (snapshot.value != null) {
      turnOrder = List<String>.from(snapshot.value as List<dynamic>);
    }
    if (!turnOrder.contains(player.id)) {
      turnOrder.add(player.id);
      await _db.child('rooms/$roomId/turnOrder').set(turnOrder);
    }
    return true;
  }

  Future<void> updateRoomStatus(String roomId, RoomStatus status) async {
    await _db.child('rooms/$roomId').update({'status': status.name});
  }

  Future<void> updatePhase(String roomId, GamePhase phase, {int? endTime}) async {
    Map<String, dynamic> updates = {
      'phase': phase.name,
      'phaseEndTime': endTime,
    };
    await _db.child('rooms/$roomId').update(updates);
  }

  Future<void> assignRoles(String roomId, Map<String, PlayerRole> roles) async {
    Map<String, dynamic> updates = {};
    roles.forEach((playerId, role) {
      updates['players/$playerId/role'] = role.name;
      updates['players/$playerId/isAlive'] = true;
    });
    await _db.child('rooms/$roomId').update(updates);
  }

  Future<void> sendMessage(String roomId, Message message) async {
    await _db.child('rooms/$roomId/messages').push().set(message.toMap());
  }

  Future<void> castVote(String roomId, String voterId, String? targetId) async {
    await _db.child('rooms/$roomId/players/$voterId/votedFor').set(targetId);
  }

  Future<void> setWerewolfVote(String roomId, String voterId, String? targetId) async {
    await _db.child('rooms/$roomId/players/$voterId/votedFor').set(targetId);
  }

  Future<void> setMedicProtect(String roomId, String targetId) async {
    await _db.child('rooms/$roomId/medicProtectId').set(targetId);
  }

  Future<void> setSeerCheck(String roomId, String targetId) async {
    await _db.child('rooms/$roomId/seerCheckId').set(targetId);
  }

  Future<void> setWitchAction(String roomId, String? targetId) async {
    await _db.child('rooms/$roomId/witchActionTargetId').set(targetId);
  }

  Future<void> killPlayer(String roomId, String playerId) async {
    await _db.child('rooms/$roomId/players/$playerId/isAlive').set(false);
    await _db.child('rooms/$roomId/lastKilledId').set(playerId);
  }

  Future<void> resurrectPlayer(String roomId, String playerId) async {
    await _db.child('rooms/$roomId/players/$playerId/isAlive').set(true);
  }

  Future<void> resetVotes(String roomId) async {
    final snapshot = await _db.child('rooms/$roomId/players').get();
    if (snapshot.value != null) {
      Map<dynamic, dynamic> players = snapshot.value as Map<dynamic, dynamic>;
      Map<String, dynamic> updates = {};
      players.forEach((key, value) {
        updates['players/$key/votedFor'] = null;
      });
      updates['werewolfVote'] = null;
      updates['medicProtectId'] = null;
      updates['seerCheckId'] = null;
      updates['witchActionTargetId'] = null;
      await _db.child('rooms/$roomId').update(updates);
    }
  }

  Future<void> resetRoomForNewGame(String roomId) async {
    final snapshot = await _db.child('rooms/$roomId/players').get();
    if (snapshot.value != null) {
      Map<dynamic, dynamic> players = snapshot.value as Map<dynamic, dynamic>;
      Map<String, dynamic> updates = {};
      
      players.forEach((key, value) {
        updates['players/$key/role'] = null;
        updates['players/$key/isAlive'] = true;
        updates['players/$key/votedFor'] = null;
      });
      
      updates['status'] = RoomStatus.lobby.name;
      updates['phase'] = GamePhase.discussione.name;
      updates['phaseEndTime'] = null;
      updates['lastKilledId'] = null;
      updates['winnerTeam'] = null;
      updates['messages'] = null;
      updates['werewolfVote'] = null;
      updates['medicProtectId'] = null;
      updates['seerCheckId'] = null;
      updates['witchActionTargetId'] = null;
      
      await _db.child('rooms/$roomId').update(updates);
    }
  }

  Future<void> removePlayer(String roomId, String playerId) async {
    await _db.child('rooms/$roomId/players/$playerId').remove();
    
    final snapshot = await _db.child('rooms/$roomId/turnOrder').get();
    if (snapshot.value != null) {
      List<String> turnOrder = List<String>.from(snapshot.value as List<dynamic>);
      turnOrder.remove(playerId);
      await _db.child('rooms/$roomId/turnOrder').set(turnOrder);
    }
  }

  Future<void> deleteRoom(String roomId) async {
    await _db.child('rooms/$roomId').remove();
  }

  // User Profile Methods
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.child('users/$uid').update(data);
  }

  Future<void> updatePlayerLastAction(String roomId, String playerId, String? targetId, {bool? hasUsedPotion}) async {
    Map<String, dynamic> updates = {'lastActionTargetId': targetId};
    if (hasUsedPotion != null) updates['hasUsedPotion'] = hasUsedPotion;
    await _db.child('rooms/$roomId/players/$playerId').update(updates);
  }

  Future<Map<dynamic, dynamic>?> getUserProfile(String uid) async {
    final snapshot = await _db.child('users/$uid').get();
    if (snapshot.exists) {
      return snapshot.value as Map<dynamic, dynamic>;
    }
    return null;
  }

  Future<void> setWinnerTeam(String roomId, String team) async {
    await _db.child('rooms/$roomId/winnerTeam').set(team);
    await _db.child('rooms/$roomId/status').set(RoomStatus.finished.name);
  }

  Future<void> incrementGamesWon(String uid) async {
    final ref = _db.child('users/$uid/gamesWon');
    final snapshot = await ref.get();
    int current = 0;
    if (snapshot.exists) {
      current = (snapshot.value as num).toInt();
    }
    await ref.set(current + 1);
  }

  Future<void> updateRoomDurations(String roomId, int discussion, int vote) async {
    await _db.child('rooms/$roomId').update({
      'discussionDuration': discussion,
      'voteDuration': vote,
    });
  }

  Future<void> updateSelectedRoles(String roomId, Map<PlayerRole, int> roles) async {
    await _db.child('rooms/$roomId/selectedRoles').set(roles.map((key, value) => MapEntry(key.name, value)));
  }

  Future<void> updateLastSystemMessage(String roomId, String text) async {
    await _db.child('rooms/$roomId').update({'lastSystemMessage': text});
  }
}
