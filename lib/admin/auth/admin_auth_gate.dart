import 'package:flutter/material.dart';

import '../../core/supabase/supabase_config.dart';
import '../../core/widgets/luxury_scaffold_background.dart';
import '../../features/auth/data/repositories/supabase_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../theme/app_theme.dart';
import '../shell/admin_shell.dart';
import 'admin_sign_in_screen.dart';
import 'staff_repository.dart';
import 'staff_role.dart';

/// Porte d'accès de la console : exige une session Supabase **et** un rôle
/// de personnel. Tout le reste (pas de session, pas de rôle, Supabase non
/// configuré, erreur) mène à un écran explicite, jamais à un accès ouvert.
class AdminAuthGate extends StatelessWidget {
  const AdminAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isReady) {
      return const _AdminMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Backend non configuré',
        detail:
            'Relancez avec --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... '
            'pour activer la console.',
      );
    }

    final authRepository = SupabaseAuthRepository(client: SupabaseConfig.client);
    final staffRepository = SupabaseStaffRepository(client: SupabaseConfig.client);

    return StreamBuilder(
      stream: authRepository.authStateChanges,
      initialData: authRepository.currentUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AdminLoading();
        }
        if (snapshot.data == null) {
          return AdminSignInScreen(authRepository: authRepository);
        }
        return _StaffGate(
          authRepository: authRepository,
          staffRepository: staffRepository,
        );
      },
    );
  }
}

class _StaffGate extends StatefulWidget {
  const _StaffGate({required this.authRepository, required this.staffRepository});

  final AuthRepository authRepository;
  final StaffRepository staffRepository;

  @override
  State<_StaffGate> createState() => _StaffGateState();
}

class _StaffGateState extends State<_StaffGate> {
  late Future<StaffIdentity> _identity;

  @override
  void initState() {
    super.initState();
    _identity = widget.staffRepository.currentIdentity();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StaffIdentity>(
      future: _identity,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const _AdminLoading();
        final identity = snapshot.data!;
        if (!identity.isStaff) {
          return _AdminMessage(
            icon: Icons.block_rounded,
            title: 'Accès refusé',
            detail:
                'Ce compte n\'a pas de rôle dans la console d\'administration. '
                'Contactez un super administrateur.',
            onSignOut: widget.authRepository.signOut,
          );
        }
        return AdminShell(
          identity: identity,
          onSignOut: widget.authRepository.signOut,
        );
      },
    );
  }
}

class _AdminLoading extends StatelessWidget {
  const _AdminLoading();

  @override
  Widget build(BuildContext context) {
    return const LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _AdminMessage extends StatelessWidget {
  const _AdminMessage({
    required this.icon,
    required this.title,
    required this.detail,
    this.onSignOut,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Future<void> Function()? onSignOut;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 40, color: AppColors.textSecondary),
                  const SizedBox(height: AppSpacing.md),
                  Text(title, style: textTheme.titleLarge, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.sm),
                  Text(detail, style: textTheme.bodySmall, textAlign: TextAlign.center),
                  if (onSignOut != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    TextButton(
                      onPressed: onSignOut,
                      child: const Text('Se déconnecter'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
