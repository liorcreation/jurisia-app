import 'package:flutter/material.dart';

import '../platform/app_platform_style.dart';
import '../shell/app_shell.dart';

/// Bouton hamburger des en-têtes mobiles : ouvre le tiroir de navigation.
/// Desktop et tablette ont une navigation permanente et utilisent le contrôle
/// unique placé dans le rail/la sidebar. Sans effet hors d'un [AppShell].
class AppShellMenuButton extends StatelessWidget {
  const AppShellMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final shell = AppShellScope.maybeOf(context);
    if (shell == null) return const SizedBox.shrink();

    final isDesktop = AppPlatformStyle.of(context) == AppPlatformStyle.desktop;
    final isTablet = AppPlatformStyle.viewportOf(context) == AppViewportClass.tablet;
    // Sur desktop, l’unique contrôle de repli se trouve dans l’en-tête de la
    // sidebar. Le hamburger des AppBars est réservé au tiroir mobile.
    if (isDesktop || isTablet) return const SizedBox.shrink();

    return IconButton(
      tooltip: 'Menu',
      icon: const Icon(Icons.menu_rounded),
      onPressed: shell.toggleNav,
    );
  }
}
