import 'package:flutter/material.dart';

import '../../core/widgets/glass_container.dart';
import '../../core/widgets/glow_focus_field.dart';
import '../../core/widgets/luxury_scaffold_background.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../theme/app_theme.dart';
import '../theme/admin_theme.dart';

/// Connexion à la console d'administration. Même authentification Supabase
/// que l'application (e-mail / mot de passe) ; l'autorisation d'entrer est
/// vérifiée ensuite par [AdminAuthGate] (rôle de personnel).
class AdminSignInScreen extends StatefulWidget {
  const AdminSignInScreen({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<AdminSignInScreen> createState() => _AdminSignInScreenState();
}

class _AdminSignInScreenState extends State<AdminSignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.authRepository.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // La suite (vérification du rôle) est pilotée par le flux d'auth de
      // [AdminAuthGate] : rien à faire de plus ici.
    } catch (error) {
      if (mounted) setState(() => _error = 'Connexion refusée. Vérifiez vos identifiants.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _AdminWordmark(),
                  const SizedBox(height: AppSpacing.xl),
                  GlassContainer(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Console d\'administration',
                          textAlign: TextAlign.center,
                          style: textTheme.titleLarge?.copyWith(fontFamily: 'Libre Caslon Display'),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        GlowFocusField(
                          child: TextField(
                            controller: _emailController,
                            enabled: !_submitting,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(labelText: 'E-mail'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        GlowFocusField(
                          child: TextField(
                            controller: _passwordController,
                            enabled: !_submitting,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'Mot de passe'),
                            onSubmitted: (_) => _submit(),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            _error!,
                            style: textTheme.bodySmall?.copyWith(color: AppColors.error),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Se connecter'),
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
    );
  }
}

class _AdminWordmark extends StatelessWidget {
  const _AdminWordmark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'JurisIA',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontFamily: 'Libre Caslon Display'),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
          decoration: BoxDecoration(
            color: AdminTheme.accent,
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          child: Text(
            'ADMIN',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: AppLetterSpacing.caps,
                ),
          ),
        ),
      ],
    );
  }
}
