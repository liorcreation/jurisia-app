import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/supabase/supabase_config.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/jurisia_mark.dart';
import '../../../../core/widgets/luxury_elevated_button.dart';
import '../../../../core/widgets/luxury_scaffold_background.dart';
import '../../../../theme/app_theme.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../controllers/auth_controller.dart';

AuthController _buildAuthController() {
  return AuthController(
    repository: SupabaseConfig.isConfigured
        ? SupabaseAuthRepository(client: SupabaseConfig.client)
        : const _UnconfiguredAuthRepository(),
  );
}

/// Utilisée uniquement tant qu'aucun projet Supabase n'est configuré : les
/// champs et le bouton de [AuthScreen] sont alors désactivés, donc aucune de
/// ces méthodes ne devrait jamais être appelée en pratique.
class _UnconfiguredAuthRepository implements AuthRepository {
  const _UnconfiguredAuthRepository();

  @override
  Stream<AuthUser?> get authStateChanges => Stream.value(null);

  @override
  AuthUser? get currentUser => null;

  @override
  Future<void> signUp({required String email, required String password}) => _unavailable();

  @override
  Future<void> signIn({required String email, required String password}) => _unavailable();

  @override
  Future<void> signOut() => _unavailable();

  Future<Never> _unavailable() =>
      Future.error(StateError('Aucun projet Supabase configuré (SUPABASE_URL / SUPABASE_ANON_KEY).'));
}

/// Écran de connexion / inscription — porte d'entrée de l'application tant
/// qu'aucune session Supabase n'est active (voir [AuthGate]).
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthController>(
      create: (_) => _buildAuthController(),
      child: const _AuthView(),
    );
  }
}

class _AuthView extends StatefulWidget {
  const _AuthView();

  @override
  State<_AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<_AuthView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();
    final isSignIn = controller.mode == AuthMode.signIn;

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const JurisIAMark(size: 56),
                    const SizedBox(height: AppSpacing.md),
                    Text('JurisIA', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: AppSpacing.xxl),
                    GlassContainer(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            isSignIn ? 'Connexion' : 'Créer un compte',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          if (!SupabaseConfig.isConfigured) ...[
                            _ConfigWarning(),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          TextField(
                            controller: _emailController,
                            enabled: SupabaseConfig.isConfigured && !controller.isSubmitting,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(labelText: 'E-mail'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            controller: _passwordController,
                            enabled: SupabaseConfig.isConfigured && !controller.isSubmitting,
                            obscureText: true,
                            autofillHints: const [AutofillHints.password],
                            decoration: const InputDecoration(labelText: 'Mot de passe'),
                            onSubmitted: (_) => _submit(controller),
                          ),
                          if (controller.errorMessage != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              controller.errorMessage!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.error),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          LuxuryElevatedButton(
                            onPressed: SupabaseConfig.isConfigured && !controller.isSubmitting
                                ? () => _submit(controller)
                                : null,
                            child: controller.isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.nightBlueDeep,
                                    ),
                                  )
                                : Text(isSignIn ? 'Se connecter' : 'Créer mon compte'),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextButton(
                            onPressed: controller.isSubmitting ? null : controller.toggleMode,
                            child: Text(
                              isSignIn
                                  ? "Pas encore de compte ? Créer un compte"
                                  : 'Déjà un compte ? Se connecter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit(AuthController controller) {
    controller.submit(email: _emailController.text, password: _passwordController.text);
  }
}

class _ConfigWarning extends StatelessWidget {
  const _ConfigWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Text(
        "Aucun projet Supabase configuré. Relancez avec "
        '--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... '
        'pour activer la connexion.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.warning),
      ),
    );
  }
}
