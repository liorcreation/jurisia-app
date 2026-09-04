import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/legal/legal_document_screen.dart';
import '../../../../core/legal/legal_documents.dart';
import '../../../../core/platform/app_platform_style.dart';
import '../../../../core/supabase/supabase_config.dart';
import '../../../../core/validation/input_limits.dart';
import '../../../profile/domain/entities/user_profession.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glow_focus_field.dart';
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
    repository: SupabaseConfig.isReady
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
  Future<void> signUp({
    required String email,
    required String password,
    String? fullName,
    String? profession,
  }) =>
      _unavailable();

  @override
  Future<void> signIn({required String email, required String password}) => _unavailable();

  @override
  Future<void> signOut() => _unavailable();

  @override
  Future<void> recordTermsAcceptance() async {}

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
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()..onTap = () => _openDocument('CGU', LegalDocuments.termsOfService);
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => _openDocument('Politique de confidentialité', LegalDocuments.privacyPolicy);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  void _openDocument(String title, String content) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LegalDocumentScreen(title: title, content: content)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();

    if (AppPlatformStyle.of(context) == AppPlatformStyle.desktop) {
      return _DesktopAuthView(
        controller: controller,
        form: _AuthForm(
          controller: controller,
          nameController: _nameController,
          emailController: _emailController,
          passwordController: _passwordController,
          termsRecognizer: _termsRecognizer,
          privacyRecognizer: _privacyRecognizer,
          onSubmit: () => _submit(controller),
          onOpenDocument: _openDocument,
        ),
        onOpenDocument: _openDocument,
      );
    }

    final isCompact = MediaQuery.sizeOf(context).height < 680;

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AuthSeal(size: isCompact ? 52 : 66),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'JurisIA',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontFamily: 'Libre Caslon Display',
                          ),
                    ),
                    if (!isCompact) ...[
                      const SizedBox(height: 4),
                      Text(
                        'L\'assistant juridique du Burkina & de l\'OHADA',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                    SizedBox(height: isCompact ? AppSpacing.lg : AppSpacing.xl),
                    _AuthForm(
                      controller: controller,
                      nameController: _nameController,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      termsRecognizer: _termsRecognizer,
                      privacyRecognizer: _privacyRecognizer,
                      onSubmit: () => _submit(controller),
                      onOpenDocument: _openDocument,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.sm,
                      children: [
                        TextButton(
                          onPressed: () => _openDocument('CGU', LegalDocuments.termsOfService),
                          child: const Text('CGU'),
                        ),
                        TextButton(
                          onPressed: () =>
                              _openDocument('Politique de confidentialité', LegalDocuments.privacyPolicy),
                          child: const Text('Politique de confidentialité'),
                        ),
                      ],
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
    controller.submit(
      email: _emailController.text,
      password: _passwordController.text,
      fullName: _nameController.text,
    );
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

// ===========================================================================
//  DESKTOP — « Le seuil du cabinet »
// ===========================================================================

class _DesktopAuthView extends StatelessWidget {
  const _DesktopAuthView({
    required this.controller,
    required this.form,
    required this.onOpenDocument,
  });

  final AuthController controller;
  final Widget form;
  final void Function(String title, String content) onOpenDocument;

  @override
  Widget build(BuildContext context) {
    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showBrand = constraints.maxWidth >= 940;
              return Row(
                children: [
                  if (showBrand) const Expanded(flex: 6, child: _BrandPanel()),
                  Expanded(
                    flex: 5,
                    child: Container(
                      decoration: showBrand
                          ? BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: AppColors.gold.withValues(alpha: 0.16),
                                  width: 1,
                                ),
                              ),
                            )
                          : null,
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (!showBrand) ...[
                                  const Center(child: JurisIAMark(size: 44)),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'JurisIA',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          fontFamily: 'Libre Caslon Display',
                                        ),
                                  ),
                                  const SizedBox(height: AppSpacing.xl),
                                ],
                                form,
                                const SizedBox(height: AppSpacing.lg),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: AppSpacing.sm,
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          onOpenDocument('CGU', LegalDocuments.termsOfService),
                                      child: const Text('CGU'),
                                    ),
                                    TextButton(
                                      onPressed: () => onOpenDocument(
                                        'Politique de confidentialité',
                                        LegalDocuments.privacyPolicy,
                                      ),
                                      child: const Text('Politique de confidentialité'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  static const _values = <(IconData, String)>[
    (Icons.forum_rounded, 'Comprendre une situation juridique, en confiance'),
    (Icons.local_library_rounded, 'La bibliothèque des textes du Burkina & de l\'OHADA'),
    (Icons.school_rounded, 'Un parcours d\'étude complet, de la L1 au Master'),
    (Icons.design_services_rounded, 'Rédiger, auditer, obtenir une note de synthèse'),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: [
        const Positioned.fill(child: IgnorePointer(child: _BrandAmbience())),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xxl + 12, AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _AuthSeal(size: 108),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'JurisIA',
                style: textTheme.displayMedium?.copyWith(
                  fontFamily: 'Libre Caslon Display',
                  height: 1.0,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Text(
                  'L\'assistant juridique pensé pour le droit burkinabè et l\'espace OHADA — '
                  'confidentiel, et sans jugement.',
                  style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary, height: 1.5),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              for (final entry in _values)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(AppRadius.small),
                          border: Border.all(color: AppColors.gold.withValues(alpha: 0.28), width: 0.7),
                        ),
                        child: Icon(entry.$1, size: 16, color: AppColors.goldLight),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Flexible(
                        child: Text(
                          entry.$2,
                          style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sceau radiant — la marque JurisIA sous un anneau d'or qui tourne
/// lentement et une lueur qui respire. Écho de l'écran de démarrage.
class _AuthSeal extends StatefulWidget {
  const _AuthSeal({required this.size});

  final double size;

  @override
  State<_AuthSeal> createState() => _AuthSealState();
}

class _AuthSealState extends State<_AuthSeal> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s * 1.5,
      height: s * 1.5,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final pulse = 0.5 + 0.5 * math.sin(_c.value * 2 * math.pi);
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: s * 1.3,
                height: s * 1.3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.08 + 0.10 * pulse),
                      blurRadius: 40 + 20 * pulse,
                      spreadRadius: 6,
                    ),
                  ],
                ),
              ),
              Transform.rotate(
                angle: _c.value * 2 * math.pi,
                child: CustomPaint(
                  size: Size(s * 1.32, s * 1.32),
                  painter: _SealRingPainter(),
                ),
              ),
              JurisIAMark(size: s),
            ],
          );
        },
      ),
    );
  }
}

class _SealRingPainter extends CustomPainter {
  const _SealRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.gold.withValues(alpha: 0.14),
    );

    const sweep = math.pi * 1.35;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          colors: [
            Color(0x00E9D48A),
            Color(0x66C9A227),
            AppColors.goldLight,
          ],
          stops: [0.0, 0.6, 1.0],
        ).createShader(rect),
    );

    // Tête lumineuse en bout d'arc.
    final headAngle = -math.pi / 2 + sweep;
    final head = center + Offset(math.cos(headAngle), math.sin(headAngle)) * radius;
    canvas.drawCircle(head, 3, Paint()..color = AppColors.goldLight);
    canvas.drawCircle(
      head,
      6,
      Paint()..color = AppColors.goldLight.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant _SealRingPainter oldDelegate) => false;
}

class _BrandAmbience extends StatefulWidget {
  const _BrandAmbience();

  @override
  State<_BrandAmbience> createState() => _BrandAmbienceState();
}

class _BrandAmbienceState extends State<_BrandAmbience> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 44))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(painter: _BrandAmbiencePainter(_controller.value)),
    );
  }
}

class _BrandAmbiencePainter extends CustomPainter {
  const _BrandAmbiencePainter(this.t);

  final double t;
  static const int _count = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < _count; i++) {
      final seed = i * 53.0;
      final baseX = seed % size.width;
      final drift = math.sin((t * 2 * math.pi) + seed) * 22;
      final x = (baseX + drift) % size.width;
      final y = (size.height * ((i / _count) + t) % 1.0);
      final radius = 0.8 + (i % 3) * 0.7;
      final opacity = 0.05 + 0.09 * (0.5 + 0.5 * math.sin((t * 2 * math.pi) + seed * 1.7));
      paint.color = AppColors.goldLight.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BrandAmbiencePainter oldDelegate) => oldDelegate.t != t;
}

// ---------------------------------------------------------------------------
//  Le formulaire (partagé : carte desktop)
// ---------------------------------------------------------------------------

class _AuthForm extends StatefulWidget {
  const _AuthForm({
    required this.controller,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.termsRecognizer,
    required this.privacyRecognizer,
    required this.onSubmit,
    required this.onOpenDocument,
  });

  final AuthController controller;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TapGestureRecognizer termsRecognizer;
  final TapGestureRecognizer privacyRecognizer;
  final VoidCallback onSubmit;
  final void Function(String title, String content) onOpenDocument;

  @override
  State<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<_AuthForm> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final textTheme = Theme.of(context).textTheme;
    final isSignIn = controller.mode == AuthMode.signIn;
    final enabled = SupabaseConfig.isReady && !controller.isSubmitting;

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ModeToggle(
            isSignIn: isSignIn,
            onChanged: controller.isSubmitting
                ? null
                : (signIn) {
                    if (signIn != isSignIn) controller.toggleMode();
                  },
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            isSignIn ? 'Content de vous revoir' : 'Rejoignez JurisIA',
            style: textTheme.titleLarge?.copyWith(fontFamily: 'Libre Caslon Display'),
          ),
          const SizedBox(height: 4),
          Text(
            isSignIn
                ? 'Connectez-vous pour retrouver vos dossiers.'
                : 'Quelques informations, et votre espace est prêt.',
            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!SupabaseConfig.isReady) ...[
            const _ConfigWarning(),
            const SizedBox(height: AppSpacing.md),
          ],
          if (!isSignIn) ...[
            GlowFocusField(
              child: TextField(
                controller: widget.nameController,
                enabled: enabled,
                textCapitalization: TextCapitalization.words,
                maxLength: AppInputLimits.fullName,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  counterText: '',
                  filled: false,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Vous êtes', style: textTheme.labelMedium?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final value in UserProfession.values)
                  _AuthProfessionChip(
                    label: value.label,
                    selected: controller.profession == value,
                    onTap: controller.isSubmitting
                        ? null
                        : () => controller.setProfession(
                              controller.profession == value ? null : value,
                            ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          GlowFocusField(
            child: TextField(
              controller: widget.emailController,
              enabled: enabled,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'E-mail', filled: false),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GlowFocusField(
            child: TextField(
              controller: widget.passwordController,
              enabled: enabled,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                filled: false,
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Afficher' : 'Masquer',
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              onSubmitted: (_) => widget.onSubmit(),
            ),
          ),
          if (!isSignIn) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: controller.termsAccepted,
                  onChanged: controller.isSubmitting
                      ? null
                      : (value) => controller.setTermsAccepted(value ?? false),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text.rich(
                      TextSpan(
                        style: textTheme.bodySmall,
                        children: [
                          const TextSpan(text: "J'accepte les "),
                          TextSpan(
                            text: 'CGU',
                            style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700),
                            recognizer: widget.termsRecognizer,
                          ),
                          const TextSpan(text: ' et la '),
                          TextSpan(
                            text: 'politique de confidentialité',
                            style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700),
                            recognizer: widget.privacyRecognizer,
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (controller.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    controller.errorMessage!,
                    style: textTheme.bodySmall?.copyWith(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          LuxuryElevatedButton(
            onPressed: enabled ? widget.onSubmit : null,
            icon: isSignIn ? Icons.login_rounded : Icons.person_add_alt_rounded,
            child: controller.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.nightBlueDeep),
                  )
                : Text(isSignIn ? 'Se connecter' : 'Créer mon compte'),
          ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.isSignIn, required this.onChanged});

  final bool isSignIn;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.legalBlueDark.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.18), width: 0.7),
      ),
      child: Row(
        children: [
          _ModeToggleTab(label: 'Connexion', active: isSignIn, onTap: () => onChanged?.call(true)),
          _ModeToggleTab(label: 'Créer un compte', active: !isSignIn, onTap: () => onChanged?.call(false)),
        ],
      ),
    );
  }
}

class _ModeToggleTab extends StatelessWidget {
  const _ModeToggleTab({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              gradient: active ? AppGradients.goldMetallic : null,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: active ? AppColors.nightBlueDeep : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthProfessionChip extends StatelessWidget {
  const _AuthProfessionChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            color: selected
                ? AppColors.gold.withValues(alpha: 0.16)
                : AppColors.legalBlueDark.withValues(alpha: 0.5),
            border: Border.all(
              color: selected
                  ? AppColors.gold.withValues(alpha: 0.6)
                  : AppColors.gold.withValues(alpha: 0.18),
              width: selected ? 1 : 0.7,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check_rounded, size: 12, color: AppColors.goldLight),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
