import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../features/auth/data/repositories/supabase_auth_repository.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../theme/app_theme.dart';
import '../navigation/home_navigation.dart';
import '../supabase/supabase_config.dart';
import '../widgets/luxury_scaffold_background.dart';

/// Porte d'authentification : affiche [AuthScreen] tant qu'aucune session
/// Supabase n'est active, [HomeNavigation] une fois connecté. Si Supabase
/// n'est pas configuré (voir [SupabaseConfig.isReady]), affiche
/// directement l'écran de connexion, qui explique alors pourquoi il ne peut
/// rien faire, plutôt que de planter au démarrage.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isReady) {
      return const AuthScreen();
    }

    final repository = SupabaseAuthRepository(client: SupabaseConfig.client);

    return StreamBuilder(
      stream: repository.authStateChanges,
      initialData: repository.currentUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthResolving();
        }
        return snapshot.data != null ? const HomeNavigation() : const AuthScreen();
      },
    );
  }
}

/// Résolution de la session Supabase : normalement invisible — elle se
/// termine pendant que [JurisIASplashScreen] tient encore l'écran. Si le
/// réseau traîne et qu'elle déborde, on ne réaffiche **pas** la marque
/// (l'utilisateur vient de la voir sur l'écran de démarrage) : seulement le
/// fond signature et trois points d'or qui respirent, sur le même dégradé
/// que le sceau qui précède — la continuité est totale.
class _AuthResolving extends StatelessWidget {
  const _AuthResolving();

  @override
  Widget build(BuildContext context) {
    return const LuxuryScaffoldBackground(
      child: Center(child: _BreathingDots()),
    );
  }
}

class _BreathingDots extends StatefulWidget {
  const _BreathingDots();

  @override
  State<_BreathingDots> createState() => _BreathingDotsState();
}

class _BreathingDotsState extends State<_BreathingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
        ..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_controller.value - i * 0.18) % 1.0;
            final wave = 0.35 + 0.65 * (0.5 - 0.5 * math.cos(phase * 2 * math.pi));
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.goldLight.withValues(alpha: 0.25 + 0.6 * wave),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
