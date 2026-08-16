import 'package:flutter/material.dart';

// Avatar rond avec initiales ou icône, utilisé dans la liste des
// conversations, le chat et l'écran "nouvelle conversation".
class AvatarCircle extends StatelessWidget {
  final String? initiales;
  final IconData? icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final double size;

  const AvatarCircle({
    super.key,
    this.initiales,
    this.icon,
    this.backgroundColor = const Color(0xFFE8F0FB),
    this.foregroundColor = const Color(0xFF1D5FA5),
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: backgroundColor,
      child: icon != null
          ? Icon(icon, color: foregroundColor, size: size * 0.45)
          : Text(
              initiales ?? '?',
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.w600,
                fontSize: size * 0.32,
              ),
            ),
    );
  }
}
