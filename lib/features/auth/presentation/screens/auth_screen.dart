import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show GoTrueClientSignInProvider, OAuthProvider;

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

  /// « Le seuil » précède le formulaire, sur mobile comme sur desktop :
  /// Google, ou e-mail — le formulaire (déjà existant, inchangé) n'apparaît
  /// qu'après un choix explicite. `AuthController` ne gère que l'e-mail/mot
  /// de passe ; OAuth passe directement par Supabase. Pas de bouton Apple :
  /// « Sign in with Apple » exige un compte Apple Developer Program payant
  /// (99 $/an) — `_signInWithProvider` reste générique (n'importe quel
  /// `OAuthProvider`) si le porteur active Apple plus tard.
  bool _showForm = false;
  bool _oauthInFlight = false;

  void _openForm() => setState(() => _showForm = true);

  /// Redirection après authentification chez le fournisseur — un schéma
  /// personnalisé sur mobile/desktop natif (voir `android/`, `ios/`,
  /// `macos/`, retenus par le système pour relancer l'app), l'origine de la
  /// page elle-même sur web. **Toujours explicite, jamais `null`** : un
  /// `redirectTo` omis se rabat côté serveur sur le « Site URL » configuré
  /// dans le tableau de bord Supabase (Authentication > URL Configuration),
  /// qui vaut `http://localhost:3000` par défaut — romprait le flux en
  /// production si ce réglage n'est pas mis à jour. Suppose que le
  /// fournisseur est activé côté Supabase (Authentication > Providers) et
  /// que cette URL figure dans sa liste d'URL de redirection autorisées —
  /// sinon Supabase répond une erreur explicite, jamais un blocage
  /// silencieux.
  Future<void> _signInWithProvider(OAuthProvider provider) async {
    if (!SupabaseConfig.isReady || _oauthInFlight) return;
    setState(() => _oauthInFlight = true);
    try {
      await SupabaseConfig.client.auth.signInWithOAuth(
        provider,
        redirectTo: kIsWeb ? Uri.base.origin : 'com.jurisia.app://login-callback/',
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connexion impossible pour le moment : $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _oauthInFlight = false);
    }
  }

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
        showForm: _showForm,
        oauthInFlight: _oauthInFlight,
        onOpenForm: _openForm,
        onBack: () => setState(() => _showForm = false),
        onSignInWithProvider: _signInWithProvider,
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

    if (!_showForm) {
      return _MobileThreshold(
        oauthInFlight: _oauthInFlight,
        onOpenForm: _openForm,
        onSignInWithProvider: _signInWithProvider,
        onOpenDocument: _openDocument,
      );
    }

    final isCompact = MediaQuery.sizeOf(context).height < 680;

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
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
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                child: _GlassBackButton(onTap: () => setState(() => _showForm = false)),
              ),
            ],
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
//  MOBILE — « Le seuil » (plein écran, avant le formulaire)
// ===========================================================================

/// Premier écran vu sur mobile, avant tout formulaire : fond quasi noir,
/// la marque qui respire au centre, un mot qui s'écrit et s'efface en
/// boucle (« Comprendre », « Rédiger »… jusqu'à « JurisIA »), une ardoise
/// de deux pilules en pied — Google (vrai flux OAuth Supabase, voir
/// `_AuthViewState._signInWithProvider`) et l'e-mail qui bascule vers le
/// formulaire existant (`_AuthForm`, inchangé).
class _MobileThreshold extends StatelessWidget {
  const _MobileThreshold({
    required this.oauthInFlight,
    required this.onOpenForm,
    required this.onSignInWithProvider,
    required this.onOpenDocument,
  });

  final bool oauthInFlight;
  final VoidCallback onOpenForm;
  final void Function(OAuthProvider provider) onSignInWithProvider;
  final void Function(String title, String content) onOpenDocument;

  static const _words = ['Comprendre', 'Rédiger', 'Consulter', 'Réviser', 'JurisIA'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.nightBlueDeep,
      body: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: _BrandAmbience())),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _AuthSeal(size: 52),
                          const SizedBox(height: AppSpacing.xl),
                          const _CyclingHeadline(words: _words),
                        ],
                      ),
                    ),
                  ),
                ),
                _ThresholdActions(
                  oauthInFlight: oauthInFlight,
                  onOpenForm: onOpenForm,
                  onSignInWithProvider: onSignInWithProvider,
                  onOpenDocument: onOpenDocument,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Un mot qui s'écrit lettre à lettre, marque une pause, s'efface, puis
/// laisse place au suivant — en boucle continue. Le curseur n'est pas un
/// trait générique mais la marque JurisIA elle-même, qui pulse doucement.
class _CyclingHeadline extends StatefulWidget {
  const _CyclingHeadline({required this.words});

  final List<String> words;

  @override
  State<_CyclingHeadline> createState() => _CyclingHeadlineState();
}

class _CyclingHeadlineState extends State<_CyclingHeadline> {
  Timer? _timer;
  int _wordIndex = 0;
  int _charCount = 0;
  bool _erasing = false;

  @override
  void initState() {
    super.initState();
    _scheduleNext();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleNext() {
    final word = widget.words[_wordIndex];
    final atFullWord = !_erasing && _charCount == word.length;
    final delay = atFullWord
        ? const Duration(milliseconds: 1100)
        : Duration(milliseconds: _erasing ? 28 : 55);
    _timer = Timer(delay, _tick);
  }

  void _tick() {
    if (!mounted) return;
    final word = widget.words[_wordIndex];
    setState(() {
      if (!_erasing) {
        if (_charCount < word.length) {
          _charCount++;
        } else {
          _erasing = true;
        }
      } else {
        if (_charCount > 0) {
          _charCount--;
        } else {
          _erasing = false;
          _wordIndex = (_wordIndex + 1) % widget.words.length;
        }
      }
    });
    _scheduleNext();
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.words[_wordIndex].substring(0, _charCount);
    final textTheme = Theme.of(context).textTheme;

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: textTheme.headlineMedium?.copyWith(
          fontFamily: 'Libre Caslon Display',
          fontWeight: FontWeight.w700,
        ),
        children: [
          TextSpan(text: visible),
          const WidgetSpan(alignment: PlaceholderAlignment.middle, child: SizedBox(width: 8)),
          const WidgetSpan(alignment: PlaceholderAlignment.middle, child: _PulsingCursorMark()),
        ],
      ),
    );
  }
}

class _PulsingCursorMark extends StatefulWidget {
  const _PulsingCursorMark();

  @override
  State<_PulsingCursorMark> createState() => _PulsingCursorMarkState();
}

class _PulsingCursorMarkState extends State<_PulsingCursorMark> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Opacity(opacity: 0.55 + 0.45 * _c.value, child: child),
      child: const JurisIAMark(size: 22),
    );
  }
}

/// L'ardoise d'actions — verre fumé, coins hauts arrondis (mobile) ou carte
/// autonome (desktop, voir `_DesktopAuthView`) : Google en vrai OAuth
/// Supabase, puis l'e-mail qui ouvre le formulaire existant. Pas de bouton
/// Apple (voir `_AuthViewState._showForm`). Jamais de bouton qui ne mène
/// nulle part : si le fournisseur n'est pas encore activé côté Supabase,
/// Supabase répond une erreur explicite (affichée en `SnackBar`, voir
/// `_AuthViewState`), jamais un blocage silencieux.
class _ThresholdActions extends StatelessWidget {
  const _ThresholdActions({
    required this.oauthInFlight,
    required this.onOpenForm,
    required this.onSignInWithProvider,
    required this.onOpenDocument,
    this.rounded = true,
  });

  final bool oauthInFlight;
  final VoidCallback onOpenForm;
  final void Function(OAuthProvider provider) onSignInWithProvider;
  final void Function(String title, String content) onOpenDocument;
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: rounded ? const BorderRadius.vertical(top: Radius.circular(28)) : BorderRadius.circular(AppRadius.large),
        gradient: AppGradients.smokedGlass,
        border: rounded
            ? Border(top: BorderSide(color: AppColors.gold.withValues(alpha: 0.18), width: 0.8))
            : Border.all(color: AppColors.gold.withValues(alpha: 0.18), width: 0.8),
        boxShadow: AppShadows.floating,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OAuthPillButton(
              label: 'Continuer avec Google',
              tone: _PillTone.light,
              leading: const _GoogleMark(size: 19),
              onTap: oauthInFlight ? null : () => onSignInWithProvider(OAuthProvider.google),
            ),
            const SizedBox(height: AppSpacing.sm),
            _OAuthPillButton(
              label: 'Se connecter ou s\'inscrire',
              tone: _PillTone.dark,
              onTap: oauthInFlight ? null : onOpenForm,
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              children: [
                TextButton(
                  onPressed: () => onOpenDocument('CGU', LegalDocuments.termsOfService),
                  child: const Text('CGU'),
                ),
                TextButton(
                  onPressed: () =>
                      onOpenDocument('Politique de confidentialité', LegalDocuments.privacyPolicy),
                  child: const Text('Politique de confidentialité'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _PillTone { light, dark }

/// Une pilule de 52px — claire (fond blanc, texte sombre, registre Google)
/// ou sombre (verre fumé + liseré d'or, registre e-mail). Icône ou glyphe
/// optionnel à gauche, jamais imposé (la pilule « Se connecter ou
/// s'inscrire » n'en a pas).
class _OAuthPillButton extends StatelessWidget {
  const _OAuthPillButton({required this.label, required this.tone, required this.onTap, this.leading});

  final String label;
  final _PillTone tone;
  final Widget? leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final light = tone == _PillTone.light;
    final enabled = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.5,
          duration: const Duration(milliseconds: 160),
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              color: light ? AppColors.textPrimary : AppColors.legalBlueDark.withValues(alpha: 0.55),
              border: light ? null : Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: AppSpacing.sm)],
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: light ? AppColors.nightBlueDeep : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Évocation du sigle Google — un anneau aux quatre teintes de sa charte
/// (bleu, vert, jaune, rouge) plutôt qu'une reproduction exacte du tracé
/// déposé, pour rester immédiatement reconnaissable sans revendiquer la
/// marque elle-même.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _GoogleMarkPainter()));
  }
}

class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final strokeWidth = radius * 0.62;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    void arc(double startDeg, double sweepDeg, Color color) {
      canvas.drawArc(
        rect,
        startDeg * math.pi / 180,
        sweepDeg * math.pi / 180,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = color,
      );
    }

    arc(-90, 80, const Color(0xFF4285F4));
    arc(-6, 96, const Color(0xFF34A853));
    arc(94, 80, const Color(0xFFFBBC05));
    arc(178, 88, const Color(0xFFEA4335));
  }

  @override
  bool shouldRepaint(covariant _GoogleMarkPainter oldDelegate) => false;
}

class _GlassBackButton extends StatelessWidget {
  const _GlassBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.legalBlueDark.withValues(alpha: 0.55),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 0.8),
          ),
          child: const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.goldLight),
        ),
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
    required this.showForm,
    required this.oauthInFlight,
    required this.onOpenForm,
    required this.onBack,
    required this.onSignInWithProvider,
  });

  final AuthController controller;
  final Widget form;
  final void Function(String title, String content) onOpenDocument;

  /// Même « seuil » que mobile, appliqué au panneau droit : Google (OAuth
  /// réel) ou e-mail, avant le formulaire existant.
  final bool showForm;
  final bool oauthInFlight;
  final VoidCallback onOpenForm;
  final VoidCallback onBack;
  final void Function(OAuthProvider provider) onSignInWithProvider;

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
                    child: Stack(
                      children: [
                        Container(
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
                                    if (showForm) ...[
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
                                    ] else ...[
                                      if (showBrand) ...[
                                        Text(
                                          'Bienvenue',
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                fontFamily: 'Libre Caslon Display',
                                              ),
                                        ),
                                        const SizedBox(height: AppSpacing.lg),
                                      ],
                                      _ThresholdActions(
                                        rounded: false,
                                        oauthInFlight: oauthInFlight,
                                        onOpenForm: onOpenForm,
                                        onSignInWithProvider: onSignInWithProvider,
                                        onOpenDocument: onOpenDocument,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (showForm)
                          Positioned(
                            top: AppSpacing.md,
                            left: AppSpacing.md,
                            child: _GlassBackButton(onTap: onBack),
                          ),
                      ],
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
