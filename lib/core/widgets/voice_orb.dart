import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// État courant de l'assistant vocal, chacun avec sa propre teinte : l'or de
/// la marque quand l'IA parle, un cobalt plus froid quand elle écoute,
/// neutre au repos ou en réflexion (correction en cours).
enum VoiceOrbState { idle, speaking, listening, thinking }

/// Orbe circulaire animé façon « Voice Mode », inspiré du rendu nuage/ciel
/// tourbillonnant de ChatGPT Voice Mode (dans la palette or/cobalt de la
/// marque plutôt que le bleu) : respire doucement au repos, tourbillonne en
/// continu, et grossit/s'illumine en réaction au niveau sonore capté
/// ([level], de 0 à 1) pendant l'écoute ou la synthèse vocale.
class VoiceOrb extends StatefulWidget {
  const VoiceOrb({
    super.key,
    required this.state,
    this.level = 0,
    this.size = 200,
  });

  final VoiceOrbState state;

  /// Niveau sonore normalisé (0 = silence, 1 = fort), lissé en interne.
  final double level;

  final double size;

  @override
  State<VoiceOrb> createState() => _VoiceOrbState();
}

class _VoiceOrbState extends State<VoiceOrb> with TickerProviderStateMixin {
  late final AnimationController _breathController =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  late final AnimationController _swirlController =
      AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();

  double _smoothedLevel = 0;

  @override
  void dispose() {
    _breathController.dispose();
    _swirlController.dispose();
    super.dispose();
  }

  List<Color> get _swirlColors {
    switch (widget.state) {
      case VoiceOrbState.idle:
        return const [AppColors.metalSilver, AppColors.metalCobalt, Color(0xFF0B1F3A)];
      case VoiceOrbState.speaking:
        return const [Colors.white, AppColors.goldLight, AppColors.gold];
      case VoiceOrbState.listening:
        return const [Colors.white, AppColors.metalCobalt, AppColors.cobalt];
      case VoiceOrbState.thinking:
        return const [AppColors.metalSilver, Color(0xFF6B7A8F), Color(0xFF1B2635)];
    }
  }

  Color get _glow {
    switch (widget.state) {
      case VoiceOrbState.idle:
        return AppColors.metalCobalt;
      case VoiceOrbState.speaking:
        return AppColors.gold;
      case VoiceOrbState.listening:
        return AppColors.cobalt;
      case VoiceOrbState.thinking:
        return AppColors.metalSilver;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lissage exponentiel simple : un niveau sonore brut « saute » d'une
    // trame à l'autre, l'orbe doit onduler plutôt que trembler.
    _smoothedLevel = _smoothedLevel * 0.7 + widget.level.clamp(0.0, 1.0) * 0.3;

    return AnimatedBuilder(
      animation: Listenable.merge([_breathController, _swirlController]),
      builder: (context, _) {
        final breath = Curves.easeInOut.transform(_breathController.value);
        final reactive = widget.state == VoiceOrbState.idle ? breath * 0.5 : _smoothedLevel;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _VoiceOrbPainter(
              colors: _swirlColors,
              glow: _glow,
              intensity: reactive,
              breath: breath,
              swirl: _swirlController.value,
            ),
          ),
        );
      },
    );
  }
}

class _VoiceOrbPainter extends CustomPainter {
  const _VoiceOrbPainter({
    required this.colors,
    required this.glow,
    required this.intensity,
    required this.breath,
    required this.swirl,
  });

  final List<Color> colors;
  final Color glow;
  final double intensity;
  final double breath;

  /// 0 → 1 en boucle, fait tourner les nappes de couleur pour l'effet
  /// « nuage vivant ».
  final double swirl;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final baseRadius = size.width / 2 * 0.52;
    final radius = baseRadius * (1 + intensity * 0.4);

    // Halo extérieur, d'autant plus large et diffus que le niveau sonore
    // est élevé.
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [glow.withValues(alpha: 0.32 + intensity * 0.25), glow.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 2.2));
    canvas.drawCircle(center, radius * 2.2, haloPaint);

    // Anneaux concentriques légers, décalés en phase, pour une texture
    // « vivante » plutôt qu'un simple disque plat.
    for (var i = 0; i < 3; i++) {
      final ringPhase = (breath + i * 0.33) % 1.0;
      final ringRadius = radius * (0.78 + ringPhase * 0.5);
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = glow.withValues(alpha: (1 - ringPhase) * 0.22);
      canvas.drawCircle(center, ringRadius, ringPaint);
    }

    // Corps de l'orbe : nappes de couleur qui tournent lentement les unes
    // sur les autres, façon nuage/ciel — le clip circulaire les contient.
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));

    final basePaint = Paint()..color = colors.last;
    canvas.drawCircle(center, radius, basePaint);

    final layerCount = colors.length - 1;
    for (var i = 0; i < layerCount; i++) {
      final angle = (swirl * 2 * math.pi) + (i * (2 * math.pi / layerCount)) + intensity * 0.6;
      final blobCenter = center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.42;
      final blobRadius = radius * (0.72 + 0.1 * math.sin(swirl * 2 * math.pi + i));
      final blobPaint = Paint()
        ..shader = RadialGradient(
          colors: [colors[i].withValues(alpha: 0.9), colors[i].withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: blobCenter, radius: blobRadius));
      canvas.drawCircle(blobCenter, blobRadius, blobPaint);
    }

    // Lumière spéculaire fixe en haut-gauche, pour la brillance "sphère".
    final specularPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withValues(alpha: 0.55), Colors.white.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center + Offset(-radius * 0.32, -radius * 0.38), radius: radius * 0.55));
    canvas.drawCircle(center + Offset(-radius * 0.32, -radius * 0.38), radius * 0.55, specularPaint);

    canvas.restore();

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: 0.35);
    canvas.drawCircle(center, radius, rimPaint);
  }

  @override
  bool shouldRepaint(covariant _VoiceOrbPainter oldDelegate) =>
      oldDelegate.colors != colors ||
      oldDelegate.glow != glow ||
      oldDelegate.intensity != intensity ||
      oldDelegate.breath != breath ||
      oldDelegate.swirl != swirl;
}

/// Libellé d'état affiché sous l'orbe (« Je vous écoute… », « … »), avec un
/// point qui pulse doucement en phase avec [state].
class VoiceOrbStatusLabel extends StatelessWidget {
  const VoiceOrbStatusLabel({super.key, required this.state});

  final VoiceOrbState state;

  String get _label => switch (state) {
        VoiceOrbState.idle => 'En attente',
        VoiceOrbState.speaking => "L'IA parle…",
        VoiceOrbState.listening => 'Je vous écoute…',
        VoiceOrbState.thinking => 'Correction en cours…',
      };

  @override
  Widget build(BuildContext context) {
    return Text(
      _label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: AppLetterSpacing.label,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
