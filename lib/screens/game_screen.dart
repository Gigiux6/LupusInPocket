import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/user_provider.dart';
import '../models/room.dart';
import '../models/player.dart';
import '../models/message.dart';
import '../widgets/custom_button.dart';
import '../data/translations.dart';
import '../theme/app_theme.dart';
import 'dart:math';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _selectedTargetId;
  GamePhase? _lastPhase;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final userProvider = context.watch<UserProvider>();
    gameProvider.setLanguage(userProvider.language);
    
    final room = gameProvider.currentRoom;
    final me = gameProvider.me;

    if (room == null || me == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (room.status == RoomStatus.finished) {
       return _buildWinnerScreen(context, room);
    }

    // Auto-pop back to lobby if room status changes back to lobby
    if (room.status == RoomStatus.lobby) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    }

    if (room.lastSystemMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(room.lastSystemMessage!),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }

    final isNight = room.phase == GamePhase.notte;
    final theme = GamePhaseTheme.get(isNight);

    if (_lastPhase != room.phase) {
      _selectedTargetId = null;
      _lastPhase = room.phase;
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        _showExitDialog(context, gameProvider);
      },
      child: AnimatedContainer(
        duration: const Duration(seconds: 1),
        color: theme.bg,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, room, gameProvider, theme),
                _buildRoleBanner(context, me, theme),
                Expanded(
                  child: Row(
                    children: [
                      // Left Side: Chat
                      Expanded(
                        flex: 2,
                        child: _buildChatSection(context, gameProvider, me, theme),
                      ),
                      // Right Side: Player List / Actions
                      Expanded(
                        flex: 1,
                        child: _buildPlayerList(context, room, gameProvider, me, theme),
                      ),
                    ],
                  ),
                ),
                _buildActionButtons(context, gameProvider, room, me, theme),
                _buildChatInput(context, gameProvider, room, me, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Room room, GameProvider provider, GamePhaseTheme theme) {
    final userProvider = context.read<UserProvider>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface.withOpacity(0.8),
        border: Border(bottom: BorderSide(color: theme.borderColor, width: 2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    theme.isNight ? Icons.nightlight_round : Icons.wb_sunny,
                    color: theme.accent,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    room.phase == GamePhase.notte ? userProvider.t('phase_notte') : (room.phase == GamePhase.discussione ? userProvider.t('phase_discussione') : userProvider.t('phase_votazione')),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: theme.accent,
                    ),
                  ),
                ],
              ),
              Text(
                "${userProvider.t('room_label')}: ${room.id}",
                style: TextStyle(color: theme.text.withOpacity(0.7), fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.text,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(color: theme.accent.withOpacity(0.5), offset: const Offset(4, 4)),
              ],
            ),
            child: Text(
              "${provider.remainingSeconds}s",
              style: TextStyle(
                color: theme.isNight ? Colors.black : Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBanner(BuildContext context, Player me, GamePhaseTheme theme) {
    final userProvider = context.read<UserProvider>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.surface.withOpacity(0.8),
        border: Border.symmetric(horizontal: BorderSide(color: theme.borderColor, width: 1)),
      ),
      child: Column(
        children: [
          Text(
            userProvider.t('identity_is'),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.text),
          ),
          Text(
            "${AppTranslations.roleEmojis[me.role?.name] ?? ''} ${userProvider.t('role_${me.role?.name}')}",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: theme.accent),
          ),
        ],
      ),
    );
  }

  Widget _buildChatSection(BuildContext context, GameProvider provider, Player me, GamePhaseTheme theme) {
    final userProvider = context.read<UserProvider>();
    _scrollToBottom();
    final filteredMessages = provider.messages.where((m) {
      if (m.senderId == 'system') return true;
      if (m.isWolfOnly) return me.role == PlayerRole.lupo;
      if (m.isMassoniOnly) return me.role == PlayerRole.massoni;
      if (theme.isNight) return false; 
      return true; 
    }).toList();

    return Container(
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: theme.borderColor, width: 2)),
      ),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: filteredMessages.length,
        itemBuilder: (context, index) {
          final m = filteredMessages[index];
          final isSystem = m.senderId == 'system';
          final isMe = m.senderId == provider.currentPlayerId;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSystem ? theme.accent.withOpacity(0.1) : (isMe ? theme.accent.withOpacity(0.2) : theme.surface.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.borderColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isSystem)
                  Text(
                    "${m.senderName}${m.isWolfOnly ? ' (${userProvider.t('role_lupo')})' : ''}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: m.isWolfOnly ? Colors.redAccent : (isMe ? theme.accent : theme.text),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  m.text,
                  style: TextStyle(color: theme.text, fontStyle: isSystem ? FontStyle.italic : FontStyle.normal),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayerList(BuildContext context, Room room, GameProvider provider, Player me, GamePhaseTheme theme) {
    final userProvider = context.read<UserProvider>();
    final players = room.players.values.toList();
    final canVote = room.phase == GamePhase.votazione || (room.phase == GamePhase.notte && (me.role == PlayerRole.lupo || me.role == PlayerRole.medico || me.role == PlayerRole.veggente || me.role == PlayerRole.strega));

    return Column(
      children: [
        if (canVote)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () => provider.vote(me.votedFor == 'abstain' ? null : 'abstain'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: me.votedFor == 'abstain' ? Colors.orangeAccent : theme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.borderColor, width: 2),
                ),
                child: Column(
                  children: [
                    Icon(Icons.not_interested, color: theme.text, size: 20),
                    Text(userProvider.t('abstain'), style: TextStyle(color: theme.text, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final p = players[index];
              final isSelected = _selectedTargetId == p.id;
              final currentPlayerId = provider.currentPlayerId;

              return GestureDetector(
                onTap: () {
                  if (!me.isAlive) return;
                  if (theme.isNight) {
                    if (me.role == PlayerRole.lupo) {
                    } else if (me.role == PlayerRole.medico) {
                      if (p.id == me.lastActionTargetId) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Non puoi proteggere lo stesso giocatore per due turni di fila!")),
                        );
                        return;
                      }
                    } else if (me.role == PlayerRole.veggente) {
                       final isWolf = p.role == PlayerRole.lupo;
                       ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(userProvider.t('seer_result', args: {
                              'name': p.name,
                              'result': isWolf ? userProvider.t('seer_yes') : userProvider.t('seer_no')
                            })),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                    } else if (me.role == PlayerRole.strega) {
                      if (me.hasUsedPotion) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(userProvider.t('err_potion_used'))),
                        );
                        return;
                      }
                      if (p.isAlive) {
                         ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(userProvider.t('err_resurrect_alive'))),
                        );
                        return;
                      }
                    } else {
                      return; 
                    }
                  }
                  if (!theme.isNight && p.id == me.id) return; 
                  if (!theme.isNight && !p.isAlive) return;
                  if (theme.isNight && me.role != PlayerRole.strega && !p.isAlive) return;

                  setState(() => _selectedTargetId = isSelected ? null : p.id);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  transform: isSelected ? (Matrix4.identity()..scale(1.05)) : Matrix4.identity(),
                  decoration: BoxDecoration(
                    color: p.isAlive 
                      ? (isSelected ? Colors.orangeAccent : theme.surface.withOpacity(0.9)) 
                      : Colors.black54,
                    border: Border.all(color: isSelected ? Colors.yellowAccent : theme.borderColor, width: isSelected ? 3 : 1),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected ? [BoxShadow(color: Colors.orange.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)] : [],
                  ),
                  child: Column(
                    children: [
                      if (p.avatarUrl != null)
                        CircleAvatar(backgroundImage: NetworkImage(p.avatarUrl!), radius: 20),
                      const SizedBox(height: 4),
                      Text(
                        "${(p.id == currentPlayerId || (me.role == PlayerRole.lupo && p.role == PlayerRole.lupo)) ? (AppTranslations.roleEmojis[p.role?.name] ?? '') : ''} ${p.name}${p.id == currentPlayerId ? " (${userProvider.t('you_suffix')})" : ""}",
                        style: TextStyle(
                          color: p.isAlive ? theme.text : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          decoration: p.isAlive ? null : TextDecoration.lineThrough,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (p.isAlive && ((!theme.isNight) || (theme.isNight && (me.role == PlayerRole.lupo || me.role == PlayerRole.medico || me.role == PlayerRole.veggente))))
                         Icon(Icons.touch_app, size: 12, color: theme.text.withOpacity(0.5)),
                      if (!p.isAlive && theme.isNight && me.role == PlayerRole.strega && !me.hasUsedPotion)
                         const Icon(Icons.auto_fix_high, size: 12, color: Colors.purpleAccent),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, GameProvider provider, Room room, Player me, GamePhaseTheme theme) {
    if (!me.isAlive) return const SizedBox.shrink();
    bool canVote = room.phase == GamePhase.votazione || (room.phase == GamePhase.notte && (me.role == PlayerRole.lupo || me.role == PlayerRole.medico || me.role == PlayerRole.veggente || me.role == PlayerRole.strega));
    if (!canVote) return const SizedBox.shrink();

    final userProvider = context.read<UserProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.surface.withOpacity(0.5),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              text: theme.isNight ? "CONFERMA" : userProvider.t('guessed'),
              color: theme.accent,
              shadows: theme.isNight ? [BoxShadow(color: AppTheme.candleGlow.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)] : null,
              onPressed: () {
                if (_selectedTargetId == null && me.votedFor == null) {
                  String hint = userProvider.t('hint_select_vote');
                  if (theme.isNight) {
                    if (me.role == PlayerRole.medico) hint = userProvider.t('hint_medic');
                    if (me.role == PlayerRole.veggente) hint = userProvider.t('hint_seer');
                    if (me.role == PlayerRole.strega) hint = userProvider.t('hint_witch');
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(hint)),
                  );
                } else if (_selectedTargetId != null) {
                  provider.vote(_selectedTargetId);
                  setState(() => _selectedTargetId = null);
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: CustomButton(
              text: userProvider.t('pass'), 
              isSecondary: true,
              color: theme.surface,
              onPressed: () => provider.vote(null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInput(BuildContext context, GameProvider provider, Room room, Player me, GamePhaseTheme theme) {
    final userProvider = context.read<UserProvider>();
    if (!me.isAlive) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.black87,
        child: Text(userProvider.t('dead_observer'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
      );
    }

    bool canChat = room.phase == GamePhase.discussione || (room.phase == GamePhase.notte && (me.role == PlayerRole.lupo || me.role == PlayerRole.massoni));
    if (!canChat) {
      String message = userProvider.t('shhh_night');
      if (room.phase == GamePhase.votazione) message = userProvider.t('shhh_vote');
      
      return Container(
        padding: const EdgeInsets.all(16),
        color: theme.bg.withOpacity(0.8),
        child: Text(message, textAlign: TextAlign.center, style: TextStyle(color: theme.text.withOpacity(0.7))),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(top: BorderSide(color: theme.borderColor, width: 2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(color: theme.text),
              decoration: InputDecoration(
                hintText: theme.isNight ? (me.role == PlayerRole.lupo ? userProvider.t('chat_wolf') : userProvider.t('chat_massoni')) : userProvider.t('chat_village'),
                hintStyle: TextStyle(color: theme.text.withOpacity(0.5)),
                border: InputBorder.none,
                filled: true,
                fillColor: theme.bg.withOpacity(0.5),
              ),
              onSubmitted: (val) => _sendMessage(provider, me, theme.isNight),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: theme.accent),
            onPressed: () => _sendMessage(provider, me, theme.isNight),
          ),
        ],
      ),
    );
  }

  void _sendMessage(GameProvider provider, Player me, bool isNight) {
    if (_messageController.text.trim().isEmpty) return;
    provider.sendMessage(
      _messageController.text.trim(), 
      isWolfOnly: isNight && me.role == PlayerRole.lupo,
      isMassoniOnly: isNight && me.role == PlayerRole.massoni,
    );
    _messageController.clear();
  }

  Widget _buildWinnerScreen(BuildContext context, Room room) {
    final winTeam = room.winnerTeam ?? 'nessuno';
    final isLupiWin = winTeam == 'lupi';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "PARTITA FINITA",
              style: TextStyle(
                fontSize: 48, 
                fontWeight: FontWeight.w900, 
                color: isDark ? Colors.white : Colors.black
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isLupiWin ? "I LUPI HANNO VINTO!" : "IL VILLAGGIO HA VINTO!",
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold, 
                color: isLupiWin ? Colors.redAccent : Colors.greenAccent
              ),
            ),
            const SizedBox(height: 40),
            CustomButton(
              text: "TORNA ALLA LOBBY",
              onPressed: () => context.read<GameProvider>().returnToLobby(),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: "ESCI",
              isSecondary: true,
              onPressed: () async {
                final name = context.read<UserProvider>().user?.name;
                await context.read<GameProvider>().leaveRoom(name: name);
                await context.read<UserProvider>().setLastRoomId(null);
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context, GameProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Vuoi uscire?"),
        content: const Text("Perderai i tuoi progressi nella partita."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ANNULLA")),
          TextButton(
            onPressed: () async {
              final name = context.read<UserProvider>().user?.name;
              await provider.leaveRoom(name: name);
              await context.read<UserProvider>().setLastRoomId(null);
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text("ESCI", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
