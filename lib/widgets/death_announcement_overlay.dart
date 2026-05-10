import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class DeathAnnouncementOverlay extends StatefulWidget {
  final String? playerName;
  final String causeOfDeath; // 'wolf', 'village', 'none'
  final VoidCallback onFinished;

  const DeathAnnouncementOverlay({
    super.key,
    this.playerName,
    required this.causeOfDeath,
    required this.onFinished,
  });

  @override
  State<DeathAnnouncementOverlay> createState() => _DeathAnnouncementOverlayState();
}

class _DeathAnnouncementOverlayState extends State<DeathAnnouncementOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    
    // Trigger Sound
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GameProvider>();
      if (widget.causeOfDeath == 'wolf') {
        provider.playSound('audio/howl.mp3');
      } else if (widget.causeOfDeath == 'village') {
        provider.playSound('audio/bell.mp3');
      }
    });

    // Auto-finish after 4 seconds
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) widget.onFinished();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String message = "";
    IconData iconData = Icons.help_outline;
    Color iconColor = Colors.white;

    if (widget.causeOfDeath == 'wolf') {
      message = "${widget.playerName} è stato sbranato dai Lupi";
      iconData = Icons.nightlight_round;
      iconColor = Colors.redAccent;
    } else if (widget.causeOfDeath == 'village') {
      message = "${widget.playerName} è stato giustiziato dal villaggio";
      iconData = Icons.link;
      iconColor = Colors.orangeAccent;
    } else {
      message = "Questa notte non è morto nessuno... per ora";
      iconData = Icons.shield_moon;
      iconColor = Colors.blueAccent;
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black, // Sfondo nero totale che copre tutto
        child: Stack(
          children: [
            // Effetto nebbia / sfumatura ai bordi
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                      Colors.black,
                    ],
                    stops: const [0.3, 0.7, 1.0],
                    radius: 1.2,
                  ),
                ),
              ),
            ),
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        iconData,
                        size: 120,
                        color: iconColor,
                        shadows: [
                          Shadow(color: iconColor.withOpacity(0.6), blurRadius: 30),
                        ],
                      ),
                      const SizedBox(height: 50),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: widget.causeOfDeath != 'none' ? BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                        ) : null,
                        child: Text(
                          message.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                            fontFamily: 'Medieval',
                            shadows: [
                              Shadow(color: iconColor.withOpacity(0.5), blurRadius: 10),
                              const Shadow(color: Colors.black, blurRadius: 20, offset: Offset(2, 2)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
