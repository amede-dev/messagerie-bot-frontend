import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/config/app_config.dart';

// Avatar rond avec initiales ou icône, utilisé dans la liste des
// conversations, le chat et l'écran "nouvelle conversation".
class AvatarCircle extends StatelessWidget {
  final String? initiales;
  final IconData? icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final double size;
  final bool estEnLigne;
  final String? imageUrl;

  const AvatarCircle({
    super.key,
    this.initiales,
    this.icon,
    this.backgroundColor = AppColors.primaryLight,
    this.foregroundColor = AppColors.primary,
    this.size = 44,
    this.estEnLigne = false,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: backgroundColor,
          backgroundImage: imageUrl == null
              ? null
              : NetworkImage(AppConfig.resolveMediaUrl(imageUrl)!),
          child: imageUrl != null
              ? null
              : icon != null
              ? Icon(icon, color: foregroundColor, size: size * 0.45)
              : Text(
                  initiales ?? '?',
                  style: TextStyle(
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
                    fontSize: size * 0.32,
                  ),
                ),
        ),
        if (estEnLigne)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
