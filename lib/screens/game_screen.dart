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

import '../widgets/death_announcement_overlay.dart';

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
  String? _seerRevealMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().setInLobby(false);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    
    // Solo se l'utente è vicino al fondo o se il messaggio è dell'utente stesso
    double threshold = 100.0;
    bool isNearBottom = _scrollController.position.maxScrollExtent - _scrollController.offset < threshold;
    
    if (isNearBottom) {
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
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final userProvider = context.watch<UserProvider>();
    gameProvider.setLanguage(userProvider.language);
    
    final room = gameProvider.currentRoom;
    final me = gameProvider.me;

    if (room == null || (me == null && room.status != RoomStatus.lobby)) {
      // Se la stanza è null, l'host ha chiuso tutto
      if (room == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
        });
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (room.deathAnnouncement != null) {
       return DeathAnnouncementOverlay(
         key: ValueKey(room.deathAnnouncement!['playerName'] ?? 'none'),
         playerName: room.deathAnnouncement!['playerName'],
         causeOfDeath: room.deathAnnouncement!['cause'] ?? 'none',
         onFinished: () {
           // CHIUNQUE può pulire l'annuncio dopo che l'animazione è finita.
           // Questo evita blocchi se l'host si disconnette durante l'overlay.
           gameProvider.clearDeathAnnouncement();
         },
       );
    }

    if (room.status == RoomStatus.finished) {
       return _buildWinnerScreen(context, room);
    }

    // Auto-pop back to lobby if room status changes back to lobby (triggered by host)
    if (room.status == RoomStatus.lobby) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Se siamo ancora sul GameScreen, facciamo un solo pop per tornare alla Lobby
          if (ModalRoute.of(context)?.isCurrent == true) {
            Navigator.of(context).pop();
          }
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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

    // Auto-navigazione quando l'host resetta la stanza o la chiude
    if (!gameProvider.isHost) {
      if (room.status == RoomStatus.lobby) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).pop();
        });
      }
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
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(context, room, gameProvider, theme),
                    _buildRoleBanner(context, me!, theme),
                    Expanded(
                      child: Row(
                        children: [
                          // Left Side: Chat
                          Expanded(
                            flex: 2,
                            child: _buildChatSection(context, gameProvider, room, me!, theme),
                          ),
                          // Right Side: Player List / Actions
                          Expanded(
                            flex: 1,
                            child: _buildPlayerList(context, room, gameProvider, me, theme),
                          ),
                        ],
                      ),
                    ),
                    _buildActionButtons(context, gameProvider, room, me!, theme),
                    _buildChatInput(context, gameProvider, room, me!, theme),
                  ],
                ),
                if (_seerRevealMessage != null)
                  _buildSeerRevealOverlay(context, _seerRevealMessage!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeerRevealOverlay(BuildContext context, String message) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.yellowAccent, width: 3),
                      boxShadow: [
                        BoxShadow(color: Colors.yellowAccent.withOpacity(0.4), blurRadius: 30, spreadRadius: 10),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.visibility, color: Colors.yellowAccent, size: 80),
                        const SizedBox(height: 24),
                        Text(
                          message.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Room room, GameProvider provider, GamePhaseTheme theme) {
    final userProvider = context.read<UserProvider>();
    return Container(
      padding: const EdgeInsets.all(16),
      height: 80, // Fixed height for better alignment
      decoration: BoxDecoration(
        color: theme.surface.withOpacity(0.8),
        border: Border(bottom: BorderSide(color: theme.borderColor, width: 2)),
      ),
      child: Stack(
        children: [
          // Left Side Info
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      theme.isNight ? Icons.nightlight_round : Icons.wb_sunny,
                      color: theme.accent,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      room.phase == GamePhase.notte ? userProvider.t('phase_notte') : (room.phase == GamePhase.discussione ? userProvider.t('phase_discussione') : userProvider.t('phase_votazione')),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: theme.accent,
                      ),
                    ),
                  ],
                ),
                Text(
                  "${userProvider.t('room_label')}: ${room.id}",
                  style: TextStyle(color: theme.text.withOpacity(0.7), fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ],
            ),
          ),
          // Central Name (Perfectly Centered)
          Align(
            alignment: Alignment.center,
            child: Text(
              provider.me?.name ?? "",
              style: TextStyle(
                color: theme.accent,
                fontWeight: FontWeight.w900,
                fontSize: 24, // Ingrandito
                letterSpacing: 1.5,
                shadows: [
                  Shadow(color: Colors.black.withOpacity(0.5), offset: const Offset(2, 2), blurRadius: 4),
                  Shadow(color: theme.accent.withOpacity(0.3), blurRadius: 10),
                ],
              ),
            ),
          ),
          // Right Side Timer
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.text,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5),
                ],
              ),
              child: Text(
                provider.formattedTime,
                style: TextStyle(
                  color: theme.bg,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBanner(BuildContext context, Player me, GamePhaseTheme theme) {
    final userProvider = context.read<UserProvider>();
    final isLupo = me.role == PlayerRole.lupo;
    
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
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.text.withOpacity(0.7)),
          ),
          Text(
            "${AppTranslations.roleEmojis[me.role?.name] ?? ''} ${userProvider.t('role_${me.role?.name}')}",
            style: TextStyle(
              fontWeight: FontWeight.w900, 
              fontSize: 24, 
              color: isLupo ? Colors.redAccent : theme.accent,
              shadows: isLupo ? [const Shadow(color: Colors.black, blurRadius: 4)] : null,
            ),
          ),
          if (theme.isNight)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                userProvider.t('instruction_${me.role?.name}'),
                style: TextStyle(
                  color: theme.text.withOpacity(0.9),
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatSection(BuildContext context, GameProvider provider, Room room, Player me, GamePhaseTheme theme) {
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
                _buildMessageText(m.text, isSystem, room.players, theme),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageText(String text, bool isSystem, Map<String, Player> players, GamePhaseTheme theme) {
    if (!isSystem) {
      return Text(
        text,
        style: TextStyle(color: theme.text),
      );
    }

    // Per messaggi di sistema, evidenziamo i nomi dei giocatori e dei ruoli
    List<TextSpan> spans = [];
    List<String> playerNames = players.values.map((p) => p.name).where((name) => name.isNotEmpty).toList();
    
    // Aggiungiamo anche i nomi dei ruoli alle parole da evidenziare
    final userProvider = context.read<UserProvider>();
    List<String> roleNames = PlayerRole.values.map((r) => userProvider.t('role_${r.name}')).toList();
    
    List<String> wordsToHighlight = [...playerNames, ...roleNames];
    
    // Altre parole rilevanti
    wordsToHighlight.addAll(['LUPI', 'VILLAGGIO', 'MORTO', 'SBRANATO', 'GIUSTIZIATO', 'WOLVES', 'VILLAGE', 'DEAD', 'MAULED', 'EXECUTED']);

    // Ordiniamo per lunghezza decrescente per evitare match parziali
    wordsToHighlight.sort((a, b) => b.length.compareTo(a.length));

    String remaining = text;
    while (remaining.isNotEmpty) {
      int firstMatchIndex = -1;
      String? matchedWord;

      for (var word in wordsToHighlight) {
        int index = remaining.toLowerCase().indexOf(word.toLowerCase());
        if (index != -1 && (firstMatchIndex == -1 || index < firstMatchIndex)) {
          firstMatchIndex = index;
          matchedWord = remaining.substring(index, index + word.length);
        }
      }

      if (firstMatchIndex == -1) {
        spans.add(TextSpan(text: remaining));
        break;
      }

      if (firstMatchIndex > 0) {
        spans.add(TextSpan(text: remaining.substring(0, firstMatchIndex)));
      }

      spans.add(TextSpan(
        text: matchedWord!,
        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontStyle: FontStyle.normal),
      ));

      remaining = remaining.substring(firstMatchIndex + matchedWord.length);
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(color: theme.text, fontStyle: FontStyle.italic, fontSize: 14, fontFamily: 'Medieval'),
        children: spans,
      ),
    );
  }

  Widget _buildPlayerList(BuildContext context, Room room, GameProvider provider, Player me, GamePhaseTheme theme) {
    final userProvider = context.read<UserProvider>();
    final players = room.players.values.where((p) {
      if (p.id == provider.currentPlayerId) {
        // Il guardiano può proteggere se stesso
        return theme.isNight && me.role == PlayerRole.guardiano;
      }
      return true;
    }).toList();
    final canVote = room.phase == GamePhase.votazione || (room.phase == GamePhase.notte && (me.role == PlayerRole.lupo || me.role == PlayerRole.guardiano || me.role == PlayerRole.veggente || me.role == PlayerRole.strega || me.role == PlayerRole.cacciatore || me.role == PlayerRole.medium || me.role == PlayerRole.mitomane));

    return Column(
      children: [
        if (canVote && room.phase == GamePhase.votazione)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTargetId = (_selectedTargetId == 'abstain') ? null : 'abstain';
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                width: double.infinity,
                transform: _selectedTargetId == 'abstain' ? (Matrix4.identity()..scale(1.05)) : Matrix4.identity(),
                decoration: BoxDecoration(
                  color: _selectedTargetId == 'abstain' 
                    ? Colors.orangeAccent 
                    : theme.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedTargetId == 'abstain' ? Colors.yellowAccent : theme.borderColor, 
                    width: _selectedTargetId == 'abstain' ? 3 : 2
                  ),
                  boxShadow: _selectedTargetId == 'abstain' ? [
                    BoxShadow(color: Colors.orange.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)
                  ] : null,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.not_interested, 
                      color: _selectedTargetId == 'abstain' ? theme.bg : theme.text, 
                      size: 20
                    ),
                    Text(
                      userProvider.t('abstain'), 
                      style: TextStyle(
                        color: _selectedTargetId == 'abstain' ? theme.bg : theme.text, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 12
                      )
                    ),
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

              // Filtra i giocatori morti: mostrali solo se Strega o Medium di notte
              if (!p.isAlive && !(room.phase == GamePhase.notte && (me.role == PlayerRole.strega || me.role == PlayerRole.medium))) {
                return const SizedBox.shrink();
              }

              return GestureDetector(
                onTap: () {
                  if (!me.isAlive) return;
                  // Blocca la selezione se ha già agito di notte
                  if (theme.isNight && me.votedFor != null) return;
                  
                  if (theme.isNight) {
                    if (me.role == PlayerRole.lupo) {
                    } else if (me.role == PlayerRole.guardiano) {
                      if (p.id == me.lastActionTargetId) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(userProvider.t('err_guardian_twice'))),
                        );
                        return;
                      }
                    } else if (me.role == PlayerRole.veggente) {
                        // Seer logic moved to Confirm button
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
                    } else if (me.role == PlayerRole.cacciatore) {
                      if (me.hasUsedBullet) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(userProvider.t('err_bullet_used'))),
                        );
                        return;
                      }
                    } else if (me.role == PlayerRole.medium) {
                      if (p.isAlive) {
                         ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(userProvider.t('err_medium_dead_only'))),
                        );
                        return;
                      }
                    } else {
                      return; 
                    }
                  }
                  if (!theme.isNight && p.id == me.id) return; 
                  if (!theme.isNight && !p.isAlive) return;
                  if (theme.isNight && me.role != PlayerRole.strega && me.role != PlayerRole.medium && !p.isAlive) return;

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
                      if (p.isAlive && ((!theme.isNight) || (theme.isNight && (me.role == PlayerRole.lupo || me.role == PlayerRole.guardiano || me.role == PlayerRole.veggente || me.role == PlayerRole.cacciatore))))
                         Icon(Icons.touch_app, size: 12, color: theme.text.withOpacity(0.5)),
                      if (!p.isAlive && theme.isNight && me.role == PlayerRole.strega && !me.hasUsedPotion)
                         const Icon(Icons.auto_fix_high, size: 12, color: Colors.purpleAccent),
                      if (p.isAlive && theme.isNight && me.role == PlayerRole.cacciatore && !me.hasUsedBullet)
                         const Icon(Icons.gps_fixed, size: 12, color: Colors.redAccent),
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
    bool canVote = room.phase == GamePhase.votazione || (room.phase == GamePhase.notte && (me.role == PlayerRole.lupo || me.role == PlayerRole.guardiano || me.role == PlayerRole.veggente || me.role == PlayerRole.strega || me.role == PlayerRole.cacciatore || me.role == PlayerRole.medium || me.role == PlayerRole.mitomane));
    if (!canVote) return const SizedBox.shrink();

    final userProvider = context.read<UserProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.surface.withOpacity(0.5),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              text: theme.isNight ? userProvider.t('btn_confirm') : userProvider.t('guessed'),
              color: theme.accent,
              shadows: theme.isNight ? [BoxShadow(color: AppTheme.candleGlow.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)] : null,
              onPressed: (me.votedFor != null) ? null : () {
                if (_selectedTargetId == null && me.votedFor == null) {
                  String hint = userProvider.t('hint_select_vote');
                  if (theme.isNight) {
                    if (me.role == PlayerRole.guardiano) hint = userProvider.t('hint_guardian');
                    if (me.role == PlayerRole.veggente) hint = userProvider.t('hint_seer');
                    if (me.role == PlayerRole.strega) hint = userProvider.t('hint_witch');
                    if (me.role == PlayerRole.cacciatore) hint = userProvider.t('hint_hunter');
                    if (me.role == PlayerRole.medium) hint = userProvider.t('instruction_medium');
                    if (me.role == PlayerRole.mitomane) hint = userProvider.t('hint_mitomane');
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(hint)),
                  );
                } else if (_selectedTargetId != null) {
                  // Previene azioni multiple di notte
                  if (theme.isNight && me.votedFor != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(userProvider.t('err_already_acted'))),
                    );
                    return;
                  }

                  // Logica specifica per il Veggente
                  if (theme.isNight && me.role == PlayerRole.veggente) {
                    final target = room.players[_selectedTargetId];
                    if (target != null) {
                      final isWolf = target.role == PlayerRole.lupo;
                      setState(() {
                        _seerRevealMessage = userProvider.t('seer_result', args: {
                          'name': target.name,
                          'result': isWolf ? userProvider.t('seer_yes') : userProvider.t('seer_no')
                        });
                      });
                      Future.delayed(const Duration(seconds: 3), () {
                        if (mounted) setState(() => _seerRevealMessage = null);
                      });
                    }
                  }

                  // Logica specifica per il Medium
                  if (theme.isNight && me.role == PlayerRole.medium) {
                    final target = room.players[_selectedTargetId];
                    if (target != null) {
                      // Buono (SI) se non è lupo o indemoniato
                      final isGood = target.role != PlayerRole.lupo && target.role != PlayerRole.indemoniato;
                      setState(() {
                        _seerRevealMessage = userProvider.t('medium_result', args: {
                          'name': target.name,
                          'result': isGood ? userProvider.t('medium_yes') : userProvider.t('medium_no')
                        });
                      });
                      Future.delayed(const Duration(seconds: 3), () {
                        if (mounted) setState(() => _seerRevealMessage = null);
                      });
                    }
                  }

                  provider.vote(_selectedTargetId);
                  setState(() => _selectedTargetId = null);
                }
              },
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
    final userProvider = context.read<UserProvider>();
    final provider = context.read<GameProvider>();
    final winTeam = room.winnerTeam ?? 'nessuno';
    final isLupiWin = winTeam == 'lupi';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF2D1B0D) : const Color(0xFFF5E6D3);
    final textColor = isDark ? const Color(0xFFE0C097) : const Color(0xFF4A2C2A);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "PARTITA FINITA",
              style: TextStyle(
                fontSize: 48, 
                fontWeight: FontWeight.w900, 
                color: textColor,
                fontFamily: 'Medieval',
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isLupiWin ? "I LUPI HANNO VINTO!" : "IL VILLAGGIO HA VINTO!",
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold, 
                color: isLupiWin ? Colors.redAccent : Colors.greenAccent,
              ),
            ),
            const SizedBox(height: 40),
            if (provider.isHost) ...[
              SizedBox(
                width: 250,
                child: CustomButton(
                  text: userProvider.t('return_to_lobby'),
                  onPressed: () => provider.returnToLobby(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 250,
                child: CustomButton(
                  text: userProvider.t('back_to_home'),
                  isSecondary: true,
                  onPressed: () async {
                    final name = userProvider.user?.name;
                    await provider.leaveRoom(name: name);
                    await userProvider.setLastRoomId(null);
                    if (context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                ),
              ),
            ] else 
              Text(
                "ATTENDI L'AMMINISTRATORE...",
                style: TextStyle(color: textColor.withOpacity(0.7), fontStyle: FontStyle.italic),
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
