import 'package:flutter/material.dart';

import '../../core/supabase/supabase_config.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/gradient_icon_badge.dart';
import '../../core/widgets/luxury_scaffold_background.dart';
import '../../features/auth/data/repositories/supabase_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../theme/app_theme.dart';
import '../shell/admin_shell.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_ambience.dart';
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

/// Attente de session — jamais une barre de progression : la marque respire
/// doucement le temps de l'aller-retour réseau, dans le même esprit que
/// l'écran de démarrage de l'application grand public (aucun indicateur de
/// chargement littéral).
class _AdminLoading extends StatefulWidget {
  const _AdminLoading();

  @override
  State<_AdminLoading> createState() => _AdminLoadingState();
}

class _AdminLoadingState extends State<_AdminLoading> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            const Positioned.fill(child: IgnorePointer(child: AdminAmbience())),
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final t = Curves.easeInOut.transform(_controller.value);
                  return Opacity(
                    opacity: 0.55 + 0.45 * t,
                    child: Transform.scale(scale: 0.94 + 0.06 * t, child: child),
                  );
                },
                child: const GradientIconBadge(
                  icon: Icons.shield_moon_rounded,
                  size: 56,
                  gradient: AdminGradients.cobaltMetallic,
                  iconColor: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
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
        body: Stack(
          children: [
            const Positioned.fill(child: IgnorePointer(child: AdminAmbience())),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    borderColor: AppColors.error.withValues(alpha: 0.35),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GradientIconBadge(
                          icon: icon,
                          size: 52,
                          gradient: LinearGradient(
                            colors: [AppColors.error.withValues(alpha: 0.9), AppColors.error.withValues(alpha: 0.5)],
                          ),
                          iconColor: AppColors.textPrimary,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          title,
                          style: textTheme.titleLarge?.copyWith(fontFamily: 'Libre Caslon Display'),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          detail,
                          style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        if (onSignOut != null) ...[
                          const SizedBox(height: AppSpacing.lg),
                          TextButton.icon(
                            onPressed: onSignOut,
                            icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.error),
                            label: const Text('Se déconnecter', style: TextStyle(color: AppColors.error)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
