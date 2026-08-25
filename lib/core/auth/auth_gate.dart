import 'package:flutter/material.dart';

import '../../features/auth/data/repositories/supabase_auth_repository.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../navigation/home_navigation.dart';
import '../supabase/supabase_config.dart';
import '../widgets/luxury_scaffold_background.dart';

/// Porte d'authentification : affiche [AuthScreen] tant qu'aucune session
/// Supabase n'est active, [HomeNavigation] une fois connecté. Si Supabase
/// n'est pas configuré (voir [SupabaseConfig.isConfigured]), affiche
/// directement l'écran de connexion, qui explique alors pourquoi il ne peut
/// rien faire, plutôt que de planter au démarrage.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isConfigured) {
      return const AuthScreen();
    }

    final repository = SupabaseAuthRepository(client: SupabaseConfig.client);

    return StreamBuilder(
      stream: repository.authStateChanges,
      initialData: repository.currentUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LuxuryScaffoldBackground(child: SizedBox.expand());
        }
        return snapshot.data != null ? const HomeNavigation() : const AuthScreen();
      },
    );
  }
}
