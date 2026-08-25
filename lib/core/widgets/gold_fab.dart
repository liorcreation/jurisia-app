import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Bouton d'action flottant en or brossé, avec halo et onde de vibration
/// Material au toucher — l'action principale du registre « Or expressif »
/// (Android).
class GoldFab extends StatelessWidget {
  const GoldFab({super.key, required this.onPressed, this.tooltip, this.icon = Icons.add_rounded});

  final VoidCallback? onPressed;
  final String? tooltip;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final button = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: onPressed == null ? null : AppShadows.goldGlow,
      ),
      child: Material(
        shape: const CircleBorder(),
        color: Colors.transparent,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: AppGradients.goldMetallic,
            shape: BoxShape.circle,
          ),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Icon(icon, color: AppColors.nightBlueDeep, size: 26),
          ),
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
