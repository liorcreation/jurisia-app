import 'package:flutter/material.dart';

import '../../features/auth/data/repositories/supabase_auth_repository.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../navigation/home_navigation.dart';
import '../supabase/supabase_config.dart';
import '../widgets/jurisia_mark.dart';
import '../widgets/luxury_scaffold_background.dart';
import '../widgets/shimmer_sweep.dart';

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

/// Résolution de la session Supabase : le premier contact avec
/// l'application, avant même de savoir si l'écran de connexion ou l'accueil
/// va s'afficher — la marque JurisIA, animée d'un balayage doré, en
/// continuité avec [JurisIASplashScreen] qui précède cet écran au
/// démarrage, plutôt qu'un canevas vide.
class _AuthResolving extends StatelessWidget {
  const _AuthResolving();

  @override
  Widget build(BuildContext context) {
    return LuxuryScaffoldBackground(
      child: Center(
        child: ShimmerSweep(
          child: JurisIAMark(size: 56),
        ),
      ),
    );
  }
}
