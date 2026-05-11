import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/user_provider.dart';
import '../models/room.dart';
import '../models/player.dart';
import '../widgets/custom_button.dart';
import 'game_screen.dart';
import '../data/translations.dart';
import 'home_screen.dart';
import '../theme/app_theme.dart';
import 'package:qr_flutter/qr_flutter.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final userProvider = context.watch<UserProvider>();
    gameProvider.setLanguage(userProvider.language);
    
    // Segna il giocatore come presente in lobby
    WidgetsBinding.instance.addPostFrameCallback((_) {
      gameProvider.setInLobby(true);
    });
    
    final room = gameProvider.currentRoom;
    final isHost = gameProvider.isHost;

    if (room == null) {
      if (gameProvider.currentPlayerId == null) {
         WidgetsBinding.instance.addPostFrameCallback((_) {
          if (ModalRoute.of(context)?.isCurrent == true) {
            context.read<UserProvider>().setLastRoomId(null);
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => HomeScreen()),
              (route) => false,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.read<UserProvider>().t('room_closed_host'))),
            );
          }
        });
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (room.status == RoomStatus.playing && ModalRoute.of(context)?.isCurrent == true) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const GameScreen()));
      }
      
      if (room.lastSystemMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(room.lastSystemMessage!),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final userProvider = context.read<UserProvider>();
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(userProvider.t('are_you_sure')),
            content: Text(isHost ? userProvider.t('exit_warning_host') : userProvider.t('exit_warning_player')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(userProvider.t('cancel'))),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(userProvider.t('exit'), style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (shouldPop == true) {
          final name = userProvider.user?.name;
          await gameProvider.leaveRoom(name: name);
          await userProvider.setLastRoomId(null);
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => HomeScreen()),
              (route) => false,
            );
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Stanza: ${room.id}'),
          centerTitle: true,
          actions: const [],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return Row(
                    children: [
                      Expanded(flex: 1, child: _buildQRView(context, room.id)),
                      const VerticalDivider(color: Colors.white54, width: 40),
                      Expanded(flex: 2, child: _buildMainLobbyView(context, room, gameProvider, isHost)),
                    ],
                  );
                } else {
                  return _buildMainLobbyView(context, room, gameProvider, isHost);
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQRView(BuildContext context, String roomId) {
    final userProvider = context.read<UserProvider>();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(userProvider.t('invita_amici', args: {}), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black, width: 4),
          ),
          child: QrImageView(
            data: roomId,
            version: QrVersions.auto,
            size: 200.0,
          ),
        ),
        const SizedBox(height: 20),
        Text('CODICE: $roomId', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
      ],
    );
  }

  Widget _buildMainLobbyView(BuildContext context, Room room, GameProvider gameProvider, bool isHost) {
    final userProvider = context.watch<UserProvider>();
    final totalRoles = room.selectedRoles.values.fold(0, (sum, count) => sum + count);
    final isCorrectCount = totalRoles == room.players.length;
    final allInLobby = room.players.values.every((p) => p.inLobby);

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              if (MediaQuery.of(context).size.width <= 800) ...[
                _buildQRView(context, room.id),
                const SizedBox(height: 40),
              ],
              Text(
                userProvider.t('players', args: {'count': room.players.length.toString()}),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ...room.players.values.map((player) => Card(
                    color: Colors.white,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: player.avatarUrl != null ? NetworkImage(player.avatarUrl!) : null,
                        child: player.avatarUrl == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(player.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                      trailing: player.id == room.hostId ? const Icon(Icons.star, color: Colors.amber) : null,
                    ),
                  )),
              const Divider(color: Colors.white54, height: 40),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: _buildHostSettings(context, gameProvider, isCorrectCount),
              ),
              if (!isHost)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    userProvider.t('waiting_host'), 
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          ),
        ),
        if (isHost)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Column(
              children: [
                if (room.players.length < 4)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      userProvider.t('min_players_error'),
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (!allInLobby)
                  const Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      "In attesa che tutti i giocatori rientrino in lobby...",
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  ),
                CustomButton(
                  text: userProvider.t('start_game'),
                  onPressed: (!isCorrectCount || room.players.length < 4 || !allInLobby)
                    ? null 
                    : () {
                        gameProvider.startGame();
                      },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHostSettings(BuildContext context, GameProvider gameProvider, bool isCorrectCount) {
    final userProvider = context.watch<UserProvider>();
    gameProvider.setLanguage(userProvider.language);
    final room = gameProvider.currentRoom;
    if (room == null) return const SizedBox.shrink();
    final isHost = gameProvider.isHost;

    final totalRoles = room.selectedRoles.values.fold(0, (sum, count) => sum + count);
    final totalPlayers = room.players.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(userProvider.t('room_settings'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        
        // Durations as already implemented
        _buildDurationSetting(context, userProvider.t('night_duration'), room.nightDuration, (val) => gameProvider.updateRoomDurations(room.discussionDuration, room.voteDuration, val), isHost),
        const SizedBox(height: 12),
        _buildDurationSetting(context, userProvider.t('discussion_duration'), room.discussionDuration, (val) => gameProvider.updateRoomDurations(val, room.voteDuration, room.nightDuration), isHost),
        const SizedBox(height: 12),
        _buildDurationSetting(context, userProvider.t('vote_duration'), room.voteDuration, (val) => gameProvider.updateRoomDurations(room.discussionDuration, val, room.nightDuration), isHost),
        
        const Divider(color: Colors.white54, height: 40),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("PERSONAGGI ATTIVI:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isCorrectCount ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "$totalRoles / $totalPlayers",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        ...PlayerRole.values.map((role) => _buildRoleConfigRow(context, role, room, gameProvider, isHost)),
        
        if (isHost && !isCorrectCount)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              "Il numero di personaggi ($totalRoles) deve essere uguale al numero di giocatori ($totalPlayers)!",
              style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildDurationSetting(BuildContext context, String label, int value, Function(int) onChanged, bool isHost) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: DropdownButton<int>(
            value: value,
            underline: const SizedBox(),
            dropdownColor: Colors.white,
            iconEnabledColor: Colors.black,
            onChanged: isHost ? (val) => val != null ? onChanged(val) : null : null,
            items: label.contains("Discussione") 
              ? const [
                  DropdownMenuItem(value: 30, child: Text("30 sec", style: TextStyle(color: Colors.black))),
                  DropdownMenuItem(value: 60, child: Text("1 min", style: TextStyle(color: Colors.black))),
                  DropdownMenuItem(value: 180, child: Text("3 min", style: TextStyle(color: Colors.black))),
                  DropdownMenuItem(value: 300, child: Text("5 min", style: TextStyle(color: Colors.black))),
                  DropdownMenuItem(value: 420, child: Text("7 min", style: TextStyle(color: Colors.black))),
                ]
              : const [
                  DropdownMenuItem(value: 15, child: Text("15 sec", style: TextStyle(color: Colors.black))),
                  DropdownMenuItem(value: 30, child: Text("30 sec", style: TextStyle(color: Colors.black))),
                  DropdownMenuItem(value: 60, child: Text("1 min", style: TextStyle(color: Colors.black))),
                ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleConfigRow(BuildContext context, PlayerRole role, Room room, GameProvider provider, bool isHost) {
    final userProvider = context.read<UserProvider>();
    final count = room.selectedRoles[role] ?? 0;
    final isMandatory = role == PlayerRole.lupo || role == PlayerRole.veggente || role == PlayerRole.guardiano;
    final isMulti = role == PlayerRole.lupo || role == PlayerRole.contadino;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.info_outline, size: 20),
            onPressed: () => _showRoleInfo(context, role),
          ),
          Expanded(
            child: Text(
              "${AppTranslations.roleEmojis[role.name] ?? ''} ${userProvider.t('role_${role.name}')}",
              style: TextStyle(
                fontWeight: count > 0 ? FontWeight.bold : FontWeight.normal,
                color: count > 0 ? Colors.black : Colors.black54,
              ),
            ),
          ),
          if (isMulti) ...[
            if (isHost)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                onPressed: () => provider.updateRoleCount(role, count - 1),
              ),
            Text("$count", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (isHost)
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                onPressed: () => provider.updateRoleCount(role, count + 1),
              ),
          ] else ...[
            if (isHost)
              Switch(
                value: count > 0,
                onChanged: isMandatory && count > 0 ? null : (val) => provider.updateRoleCount(role, val ? 1 : 0),
                activeColor: AppTheme.leatherBrown,
                activeTrackColor: AppTheme.leatherBrown.withOpacity(0.4),
                inactiveThumbColor: AppTheme.dayText.withOpacity(0.3),
                inactiveTrackColor: AppTheme.dayText.withOpacity(0.1),
              )
            else
              Icon(
                count > 0 ? Icons.check_circle : Icons.radio_button_unchecked,
                color: count > 0 ? Colors.blueAccent : Colors.white24,
              ),
          ],
        ],
      ),
    );
  }

  void _showRoleInfo(BuildContext context, PlayerRole role) {
    final userProvider = context.read<UserProvider>();
    String description = userProvider.t('info_${role.name}');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(userProvider.t('role_${role.name}')),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(userProvider.t('close')),
          ),
        ],
      ),
    );
  }
}
