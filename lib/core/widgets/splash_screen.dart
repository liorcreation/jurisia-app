import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'jurisia_mark.dart';

/// Écran de démarrage de JurisIA — « le sceau radiant ».
///
/// La première image que voit l'utilisateur : la marque JurisIA se révèle
/// **une seule fois**, portée par une gerbe de lumière dorée, une onde qui
/// se propage, un balayage métallique et une poussière d'or en suspension.
/// Aucune barre de progression : rien qui évoque l'attente, seulement la
/// marque mise en scène. Le rideau se lève ensuite en fondu sur un fond
/// strictement identique à celui de l'application ([AppGradients.background]),
/// si bien que la transition est imperceptible — l'utilisateur ne revoit
/// jamais le logo après cet instant.
class JurisIASplashScreen extends StatefulWidget {
  const JurisIASplashScreen({super.key, required this.child});

  final Widget child;

  @override
  State<JurisIASplashScreen> createState() => _JurisIASplashScreenState();
}

class _JurisIASplashScreenState extends State<JurisIASplashScreen>
    with TickerProviderStateMixin {
  /// Séquence de révélation, jouée une fois.
  late final AnimationController _intro;

  /// Boucle lente et permanente : dérive des lueurs d'ambiance, rotation de
  /// la gerbe de rayons, respiration de la marque et poussière d'or.
  late final AnimationController _ambient;

  /// Lever de rideau : fait disparaître le sceau en fondu au profit de
  /// l'application.
  late final AnimationController _outro;

  late final Animation<double> _markOpacity;
  late final Animation<double> _markScale;
  late final Animation<double> _glow;
  late final Animation<double> _rays;
  late final Animation<double> _halo;
  late final Animation<double> _wordOpacity;
  late final Animation<double> _wordSpacing;
  late final Animation<double> _sheen;
  late final Animation<double> _rule;
  late final Animation<double> _tagline;

  bool _showApp = false;
  bool _reduceHandled = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
    _outro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );

    _markOpacity = _seg(0.00, 0.26);
    _markScale = _seg(0.00, 0.44, curve: Curves.easeOutBack);
    _glow = _seg(0.02, 0.50);
    _rays = _seg(0.06, 0.46);
    _halo = _seg(0.24, 0.66, curve: Curves.easeOutCubic);
    _wordOpacity = _seg(0.40, 0.62);
    _wordSpacing = _seg(0.40, 0.86, curve: Curves.easeOutCubic);
    _sheen = _seg(0.50, 0.86, curve: Curves.easeInOutCubic);
    _rule = _seg(0.60, 0.84, curve: Curves.easeOutCubic);
    _tagline = _seg(0.74, 0.96);

    _outro.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _showApp = true);
      }
    });

    _intro.forward().whenComplete(() async {
      await Future<void>.delayed(const Duration(milliseconds: 380));
      if (mounted) _outro.forward();
    });
  }

  Animation<double> _seg(double begin, double end, {Curve curve = Curves.fastOutSlowIn}) {
    return CurvedAnimation(parent: _intro, curve: Interval(begin, end, curve: curve));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mouvement réduit : on saute la mise en scène, on tient la marque un
    // court instant, puis on lève le rideau.
    if (_reduceHandled) return;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _reduceHandled = true;
      _ambient.stop();
      _intro.value = 1.0;
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    _outro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showApp) return widget.child;

    return AnimatedBuilder(
      animation: Listenable.merge([_intro, _ambient, _outro]),
      builder: (context, _) {
        final lift = Curves.easeOut.transform(_outro.value);
        return DecoratedBox(
          decoration: const BoxDecoration(gradient: AppGradients.background),
          child: Opacity(
            opacity: 1 - lift,
            child: Transform.scale(
              scale: 1 + 0.05 * lift,
              child: _Seal(
                ambient: _ambient.value,
                introDone: _intro.isCompleted && !_reduceHandled,
                markOpacity: _markOpacity.value,
                markScale: _markScale.value,
                glow: _glow.value,
                rays: _rays.value,
                halo: _halo.value,
                wordOpacity: _wordOpacity.value,
                wordSpacing: _wordSpacing.value,
                sheen: _sheen.value,
                rule: _rule.value,
                tagline: _tagline.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Composition du sceau : couches empilées, du fond atmosphérique à la
/// poussière d'or au premier plan.
class _Seal extends StatelessWidget {
  const _Seal({
    required this.ambient,
    required this.introDone,
    required this.markOpacity,
    required this.markScale,
    required this.glow,
    required this.rays,
    required this.halo,
    required this.wordOpacity,
    required this.wordSpacing,
    required this.sheen,
    required this.rule,
    required this.tagline,
  });

  final double ambient;
  final bool introDone;
  final double markOpacity;
  final double markScale;
  final double glow;
  final double rays;
  final double halo;
  final double wordOpacity;
  final double wordSpacing;
  final double sheen;
  final double rule;
  final double tagline;

  @override
  Widget build(BuildContext context) {
    final breathe = introDone ? math.sin(ambient * 2 * math.pi) : 0.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _AuroraPainter(t: ambient)),
        CustomPaint(
          painter: _RadiancePainter(
            rotation: ambient * 2 * math.pi,
            rays: rays,
            glow: glow,
            halo: halo,
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _mark(breathe),
              const SizedBox(height: AppSpacing.lg),
              _wordmark(context),
              const SizedBox(height: AppSpacing.md),
              _hairline(),
              const SizedBox(height: AppSpacing.sm + 2),
              _taglineText(context),
            ],
          ),
        ),
        // Balayage métallique : un unique voile lumineux diagonal qui
        // traverse toute la scène pendant la révélation, sans bord dur.
        if (sheen > 0 && sheen < 1)
          IgnorePointer(child: CustomPaint(painter: _SheenPainter(sheen))),
        IgnorePointer(
          child: CustomPaint(painter: _DustPainter(t: ambient, opacity: markOpacity * 0.9)),
        ),
      ],
    );
  }

  Widget _mark(double breathe) {
    final scale = (0.60 + 0.40 * markScale) * (1 + 0.014 * breathe);
    return Opacity(
      opacity: markOpacity.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: scale,
        child: SizedBox(
          width: 176,
          height: 176,
          child: Stack(
            alignment: Alignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.goldLight.withValues(alpha: 0.30 * glow),
                      AppColors.gold.withValues(alpha: 0.10 * glow),
                      AppColors.gold.withValues(alpha: 0),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
                child: const SizedBox.expand(),
              ),
              const JurisIAMark(size: 104),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wordmark(BuildContext context) {
    final spacing = 12.0 * (1 - wordSpacing) + AppLetterSpacing.headline * wordSpacing;
    return Opacity(
      opacity: wordOpacity.clamp(0.0, 1.0),
      child: ShaderMask(
        shaderCallback: (bounds) => AppGradients.goldMetallic.createShader(bounds),
        child: Text(
          'JurisIA',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                letterSpacing: spacing,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }

  Widget _hairline() {
    return Opacity(
      opacity: rule.clamp(0.0, 1.0),
      child: Container(
        width: 180 * rule,
        height: 1,
        decoration: const BoxDecoration(gradient: AppGradients.goldSheen),
      ),
    );
  }

  Widget _taglineText(BuildContext context) {
    return Opacity(
      opacity: (tagline * 0.85).clamp(0.0, 1.0),
      child: Text(
        'ASSISTANT JURIDIQUE',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.goldLight,
              letterSpacing: AppLetterSpacing.caps,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

/// Lueurs d'ambiance (« mesh gradient ») qui dérivent lentement en boucle :
/// une touche d'or, une de cobalt, une de bleu juridique. Assez sourdes pour
/// ne jamais éclipser la marque, juste de quoi rendre le fond vivant.
class _AuroraPainter extends CustomPainter {
  _AuroraPainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p = t * 2 * math.pi;
    final reach = size.longestSide;

    _blob(canvas, Offset(w * (0.84 + 0.06 * math.sin(p)), h * (0.08 + 0.05 * math.cos(p * 0.8))),
        reach * 0.55, AppColors.gold, 0.14);
    _blob(canvas, Offset(w * (0.10 + 0.06 * math.cos(p * 1.1)), h * (0.92 + 0.04 * math.sin(p))),
        reach * 0.60, AppColors.cobalt, 0.10);
    _blob(canvas, Offset(w * (0.50 + 0.10 * math.sin(p * 0.6)), h * (0.40 + 0.06 * math.cos(p))),
        reach * 0.52, AppColors.legalBlueLight, 0.13);
  }

  void _blob(Canvas canvas, Offset center, double radius, Color color, double maxAlpha) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: maxAlpha), color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) => oldDelegate.t != t;
}

/// La lumière qui émane de la marque : un bassin doré, une gerbe de rayons
/// en rotation infiniment lente, et une onde unique qui se propage vers
/// l'extérieur (le « ping ») pendant la révélation.
class _RadiancePainter extends CustomPainter {
  _RadiancePainter({
    required this.rotation,
    required this.rays,
    required this.glow,
    required this.halo,
  });

  final double rotation;
  final double rays;
  final double glow;
  final double halo;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 12);
    final unit = size.shortestSide;

    if (glow > 0) {
      final radius = unit * 0.44;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.16 * glow),
            AppColors.gold.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    if (rays > 0) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation * 0.12);
      const count = 20;
      final maxLen = unit * 0.66;
      for (var i = 0; i < count; i++) {
        final angle = i * (2 * math.pi / count);
        final long = i.isEven;
        final len = long ? maxLen : maxLen * 0.58;
        final half = long ? 0.045 : 0.028;
        final path = Path()
          ..moveTo(0, 0)
          ..lineTo(math.cos(angle - half) * len, math.sin(angle - half) * len)
          ..lineTo(math.cos(angle + half) * len, math.sin(angle + half) * len)
          ..close();
        final paint = Paint()
          ..shader = RadialGradient(
            colors: [
              AppColors.goldLight.withValues(alpha: 0.11 * rays),
              AppColors.goldLight.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: len));
        canvas.drawPath(path, paint);
      }
      canvas.restore();
    }

    if (halo > 0 && halo < 1) {
      final radius = unit * (0.14 + 0.52 * halo);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * (1 - halo)
        ..color = AppColors.goldLight.withValues(alpha: 0.55 * (1 - halo));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadiancePainter oldDelegate) =>
      oldDelegate.rotation != rotation ||
      oldDelegate.rays != rays ||
      oldDelegate.glow != glow ||
      oldDelegate.halo != halo;
}

/// Balayage métallique : un voile lumineux diagonal, largement estompé sur
/// ses deux bords, qui traverse toute la scène une seule fois. Peint sur
/// toute la hauteur — jamais de bord franc — en fondu additif discret.
class _SheenPainter extends CustomPainter {
  _SheenPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // Intensité en cloche : nulle au début et à la fin, maximale au centre
    // du passage, pour que l'apparition et la sortie soient invisibles.
    final envelope = math.sin(progress.clamp(0.0, 1.0) * math.pi);
    if (envelope <= 0.001) return;

    final bandWidth = size.width * 0.6;
    final travel = (progress * 2.3 - 0.65) * size.width;
    final rect = Rect.fromLTWH(travel - bandWidth / 2, -size.height, bandWidth, size.height * 3);
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        AppColors.goldLight.withValues(alpha: 0),
        AppColors.goldLight.withValues(alpha: 0.10 * envelope),
        AppColors.goldLight.withValues(alpha: 0.22 * envelope),
        AppColors.goldLight.withValues(alpha: 0.10 * envelope),
        AppColors.goldLight.withValues(alpha: 0),
      ],
      stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
    );

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-0.35);
    canvas.translate(-size.width / 2, -size.height / 2);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = gradient.createShader(rect)
        ..blendMode = BlendMode.plus,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SheenPainter oldDelegate) => oldDelegate.progress != progress;
}

/// Poussière d'or en suspension : quelques motes qui remontent lentement en
/// boucle, scintillant à mi-course — ce qui rend l'écran « vivant » plutôt
/// que figé.
class _DustPainter extends CustomPainter {
  _DustPainter({required this.t, required this.opacity});

  final double t;
  final double opacity;

  static final math.Random _rng = math.Random(7);
  static final List<_Mote> _motes = List.generate(
    18,
    (_) => _Mote(
      x: _rng.nextDouble(),
      radius: 0.6 + _rng.nextDouble() * 1.7,
      speed: 0.18 + _rng.nextDouble() * 0.5,
      drift: _rng.nextDouble() * 2 * math.pi,
      phase: _rng.nextDouble(),
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final paint = Paint();
    for (final mote in _motes) {
      final progress = (mote.phase + t * mote.speed) % 1.0;
      final y = size.height * (1.05 - progress * 1.15);
      final x = size.width * mote.x + math.sin(progress * 2 * math.pi + mote.drift) * 16;
      final alpha = (math.sin(progress * math.pi) * 0.5 * opacity).clamp(0.0, 1.0);
      paint.color = AppColors.goldLight.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), mote.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DustPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.opacity != opacity;
}

class _Mote {
  const _Mote({
    required this.x,
    required this.radius,
    required this.speed,
    required this.drift,
    required this.phase,
  });

  final double x;
  final double radius;
  final double speed;
  final double drift;
  final double phase;
}
