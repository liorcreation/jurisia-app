import 'package:flutter/material.dart';

import '../platform/app_platform_style.dart';
import '../shell/app_shell.dart';

/// Bouton hamburger présent dans chaque `AppBar` / `IosLargeTitleBar` des
/// cinq espaces : ouvre la sidebar unifiée — le tiroir sur mobile, ou déplie
/// le rail sur desktop. La tablette garde un rail permanent et n'affiche donc
/// pas ce bouton. Sans effet si aucun [AppShell] n'englobe l'écran.
class AppShellMenuButton extends StatelessWidget {
  const AppShellMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final shell = AppShellScope.maybeOf(context);
    if (shell == null) return const SizedBox.shrink();

    final isDesktop = AppPlatformStyle.of(context) == AppPlatformStyle.desktop;
    final isTablet =
        AppPlatformStyle.viewportOf(context) == AppViewportClass.tablet;
    if (isTablet) return const SizedBox.shrink();
    final collapsed = isDesktop && shell.railCollapsed;

    return IconButton(
      tooltip: isDesktop
          ? (collapsed ? 'Déplier la navigation' : 'Replier la navigation')
          : 'Menu',
      icon: Icon(collapsed ? Icons.menu_open_rounded : Icons.menu_rounded),
      onPressed: shell.toggleNav,
    );
  }
}
