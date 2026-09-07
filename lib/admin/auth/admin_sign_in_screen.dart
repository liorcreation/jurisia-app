import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/widgets/glass_container.dart';
import '../../core/widgets/glow_focus_field.dart';
import '../../core/widgets/jurisia_mark.dart';
import '../../core/widgets/luxury_scaffold_background.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../theme/app_theme.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_ambience.dart';

/// Connexion à la console d'administration — « le seuil de la console » :
/// même authentification Supabase que l'application (e-mail / mot de passe),
/// mais un registre entièrement cobalt pour qu'un opérateur ne se croie
/// jamais dans l'application grand public. L'autorisation d'entrer est
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
  bool _obscure = true;
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
        body: Stack(
          children: [
            const Positioned.fill(child: IgnorePointer(child: AdminAmbience())),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _AdminSeal(),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'ACCÈS RÉSERVÉ AU PERSONNEL',
                        style: textTheme.labelSmall?.copyWith(
                          color: AdminTheme.accentLight,
                          letterSpacing: AppLetterSpacing.caps,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Console d\'administration',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineMedium?.copyWith(fontFamily: 'Libre Caslon Display'),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      GlassContainer(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        borderColor: AdminTheme.accent.withValues(alpha: 0.35),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            GlowFocusField(
                              child: TextField(
                                controller: _emailController,
                                enabled: !_submitting,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'E-mail',
                                  prefixIcon: Icon(Icons.mail_outline_rounded, size: 18),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            GlowFocusField(
                              child: TextField(
                                controller: _passwordController,
                                enabled: !_submitting,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: 'Mot de passe',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      size: 18,
                                    ),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                onSubmitted: (_) => _submit(),
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: textTheme.bodySmall?.copyWith(color: AppColors.error),
                                    ),
                                  ),
                                ],
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
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Un compte JurisIA sans rôle de personnel se verra refuser l\'accès.',
                        textAlign: TextAlign.center,
                        style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled),
                      ),
                    ],
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

/// Le sceau de la console : la marque cerclée d'un anneau cobalt à tête
/// lumineuse tournante — le pendant admin de `_AuthSeal` de l'écran de
/// connexion grand public, jamais un simple logo statique.
class _AdminSeal extends StatelessWidget {
  const _AdminSeal();

  static const double _size = 96;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.3, -0.4),
                radius: 1.1,
                colors: [AppColors.nightBlue, AppColors.nightBlueDeep],
              ),
              boxShadow: AdminGradients.cobaltGlowSoft,
            ),
          ),
          const _SealRing(size: _size),
          JurisIAMark(size: _size * 0.48, gradient: AdminGradients.cobaltMetallic),
        ],
      ),
    );
  }
}

class _SealRing extends StatefulWidget {
  const _SealRing({required this.size});

  final double size;

  @override
  State<_SealRing> createState() => _SealRingState();
}

class _SealRingState extends State<_SealRing> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 6))
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
      builder: (context, _) => CustomPaint(
        size: Size.square(widget.size),
        painter: _SealRingPainter(progress: _controller.value),
      ),
    );
  }
}

class _SealRingPainter extends CustomPainter {
  const _SealRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = AdminTheme.accent.withValues(alpha: 0.26),
    );

    const sweepAngle = math.pi * 0.5;
    final start = progress * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweepAngle,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          endAngle: sweepAngle,
          colors: [AdminTheme.accentLight.withValues(alpha: 0), AdminTheme.accentLight],
          transform: GradientRotation(start),
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(covariant _SealRingPainter oldDelegate) => oldDelegate.progress != progress;
}
