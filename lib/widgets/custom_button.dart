import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../providers/user_provider.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final bool isSecondary;
  final List<BoxShadow>? shadows;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.isSecondary = false,
    this.shadows,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color ?? (widget.isSecondary ? AppTheme.daySurface : AppTheme.leatherBrown);
    
    final hsl = HSLColor.fromColor(baseColor);
    final darkerShadow = hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();

    return GestureDetector(
      onTapDown: (_) {
        if (widget.onPressed != null) {
          setState(() => _isPressed = true);
          final effectsVolume = context.read<UserProvider>().effectsVolume;
          context.read<GameProvider>().playWhoosh(effectsVolume);
        }
      },
      onTapUp: (_) {
        if (widget.onPressed != null) {
          setState(() => _isPressed = false);
          widget.onPressed!();
        }
      },
      onTapCancel: () {
        if (widget.onPressed != null) {
          setState(() => _isPressed = false);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: EdgeInsets.only(top: _isPressed ? 4 : 0),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.isSecondary ? AppTheme.leatherBrown : AppTheme.goldBorder,
            width: 2,
          ),
          boxShadow: [
            if (!_isPressed && widget.onPressed != null)
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                offset: const Offset(0, 4),
                blurRadius: 4,
              ),
            if (!_isPressed && widget.shadows != null) ...widget.shadows!,
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.text,
              style: GoogleFonts.medievalSharp(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: (baseColor == AppTheme.leatherBrown || hsl.lightness < 0.4) ? Colors.white : AppTheme.dayText,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
