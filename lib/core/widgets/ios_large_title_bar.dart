import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Barre de titre iOS : le grand titre descend sur un fond en flou de vraie
/// vibrance plutôt qu'une barre pleine — le registre « Verre glacé ».
class IosLargeTitleBar extends StatelessWidget implements PreferredSizeWidget {
  const IosLargeTitleBar({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(84);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.nightBlue.withValues(alpha: 0.78),
                AppColors.nightBlue.withValues(alpha: 0.52),
              ],
            ),
            border: const Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 8, AppSpacing.sm, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (actions != null)
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: actions!),
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xs),
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 25),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
