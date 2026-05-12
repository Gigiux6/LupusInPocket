import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../data/translations.dart';
import '../providers/user_provider.dart';

class DeathAnnouncementOverlay extends StatefulWidget {
  final List<Map<String, dynamic>> events;
  final VoidCallback onFinished;

  const DeathAnnouncementOverlay({
    super.key,
    required this.events,
    required this.onFinished,
  });

  @override
  State<DeathAnnouncementOverlay> createState() => _DeathAnnouncementOverlayState();
}

class _DeathAnnouncementOverlayState extends State<DeathAnnouncementOverlay> with TickerProviderStateMixin {
  late AnimationController _fireController;
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isExiting = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    
    _fireController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _startSequence();
  }

  void _startSequence() {
    _triggerSound(_currentIndex);
    
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (_currentIndex < widget.events.length - 1) {
        setState(() {
          _currentIndex++;
        });
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
        _triggerSound(_currentIndex);
      } else {
        timer.cancel();
        setState(() => _isExiting = true);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) widget.onFinished();
        });
      }
    });
  }

  void _triggerSound(int index) {
    if (index >= widget.events.length) return;
    final event = widget.events[index];
    final cause = event['cause'] ?? 'none';
    final provider = context.read<GameProvider>();
    
    if (cause == 'suspicious') {
      provider.playSound('audio/howl.mp3');
    } else if (cause == 'village') {
      provider.playSound('audio/bell.mp3');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fireController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildFireAnimation() {
    return AnimatedBuilder(
      animation: _fireController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.local_fire_department, size: 140 + (10 * _fireController.value), color: Colors.orange.withOpacity(0.3)),
            Icon(Icons.local_fire_department, size: 120 + (5 * _fireController.value), color: Colors.deepOrangeAccent),
            Icon(Icons.local_fire_department, size: 100 - (5 * _fireController.value), color: Colors.yellowAccent),
          ],
        );
      },
    );
  }

  Widget _buildResurrectionAnimation() {
    return AnimatedBuilder(
      animation: _fireController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.auto_fix_high, size: 140 + (20 * _fireController.value), color: Colors.blueAccent.withOpacity(0.3)),
            Transform.rotate(
              angle: _fireController.value * 0.2,
              child: const Icon(Icons.brightness_7, size: 110, color: Colors.cyanAccent),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: _isExiting ? 0.0 : 1.0,
        child: Container(
          color: Colors.black,
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.events.length,
            itemBuilder: (context, index) {
              return _buildEventSlide(widget.events[index]);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEventSlide(Map<String, dynamic> event) {
    final userProvider = context.read<UserProvider>();
    final lang = userProvider.language;
    
    final String cause = event['cause'] ?? 'none';
    final String? playerName = event['playerName'];

    String message = "";
    Widget iconWidget = const Icon(Icons.help_outline, size: 120, color: Colors.white);
    Color themeColor = Colors.white;

    if (cause == 'suspicious') {
      message = AppTranslations.translate('msg_suspicious_deaths', lang, args: {'names': playerName ?? '???'});
      if (playerName != null && !playerName.contains(' e ')) {
         message = AppTranslations.translate('msg_sbranato', lang, args: {'name': playerName});
      }
      iconWidget = const Icon(Icons.nightlight_round, size: 120, color: Colors.redAccent);
      themeColor = Colors.redAccent;
    } else if (cause == 'village') {
      message = AppTranslations.translate('msg_voted_out', lang, args: {'name': playerName ?? '???'});
      iconWidget = _buildFireAnimation();
      themeColor = Colors.orangeAccent;
    } else if (cause == 'resurrection') {
      message = AppTranslations.translate('msg_resurrected', lang, args: {'name': playerName ?? '???'});
      iconWidget = _buildResurrectionAnimation();
      themeColor = Colors.cyanAccent;
    } else if (cause == 'none_day') {
      message = AppTranslations.translate('msg_no_execution', lang);
      iconWidget = const Icon(Icons.block, size: 120, color: Colors.orangeAccent);
      themeColor = Colors.orangeAccent;
    } else {
      message = AppTranslations.translate('msg_no_deaths', lang);
      iconWidget = const Icon(Icons.verified_user, size: 120, color: Colors.blueAccent);
      themeColor = Colors.blueAccent;
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(height: 50),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: !cause.startsWith('none') ? BoxDecoration(
              color: themeColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: themeColor.withOpacity(0.2)),
            ) : null,
            child: Text(
              message.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                fontFamily: 'Medieval',
                shadows: [
                  Shadow(color: themeColor.withOpacity(0.5), blurRadius: 10),
                  const Shadow(color: Colors.black, blurRadius: 20, offset: Offset(2, 2)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
