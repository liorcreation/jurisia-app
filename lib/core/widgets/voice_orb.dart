import 'dart:math' as math;
import 'dart:ui' as ui;

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

  /// Anime la BASCULE d'une palette d'état à l'autre (ex. idle → speaking) :
  /// sans elle, changer d'état fait « sauter » les couleurs de l'orbe d'une
  /// frame à l'autre, un détail qui trahit une interface pas assez soignée
  /// pour une conversation vocale censée se sentir vivante et continue.
  late final AnimationController _stateTransition =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 520))..value = 1;

  late List<Color> _fromColors = _colorsFor(widget.state);
  late Color _fromGlow = _glowFor(widget.state);

  double _smoothedLevel = 0;

  @override
  void didUpdateWidget(covariant VoiceOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      // Repart de la palette actuellement affichée (potentiellement déjà en
      // cours d'interpolation) plutôt que de l'état précédent figé — une
      // bascule rapide d'état ne doit jamais produire de à-coup visuel.
      _fromColors = _currentColors;
      _fromGlow = _currentGlow;
      _stateTransition
        ..stop()
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    _swirlController.dispose();
    _stateTransition.dispose();
    super.dispose();
  }

  /// Quatre teintes par état, de la plus claire (point de lumière) à la plus
  /// profonde (bord ombré) — pensées comme les arrêts d'un dégradé de
  /// sphère éclairée, pas comme des nappes de couleur distinctes.
  static List<Color> _colorsFor(VoiceOrbState state) {
    switch (state) {
      case VoiceOrbState.idle:
        return const [Color(0xFFEAF0FB), AppColors.metalSilver, AppColors.metalCobalt, Color(0xFF0A1930)];
      case VoiceOrbState.speaking:
        return const [Colors.white, AppColors.goldLight, AppColors.gold, AppColors.goldDark];
      case VoiceOrbState.listening:
        return const [Color(0xFFF3F6FF), Color(0xFFAFC6FF), AppColors.cobalt, Color(0xFF102459)];
      case VoiceOrbState.thinking:
        return const [Color(0xFFEDEFF3), AppColors.metalSilver, Color(0xFF5C6A80), Color(0xFF141C29)];
    }
  }

  static Color _glowFor(VoiceOrbState state) {
    switch (state) {
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

  List<Color> get _currentColors {
    final target = _colorsFor(widget.state);
    final t = Curves.easeInOut.transform(_stateTransition.value);
    return [for (var i = 0; i < target.length; i++) Color.lerp(_fromColors[i], target[i], t)!];
  }

  Color get _currentGlow =>
      Color.lerp(_fromGlow, _glowFor(widget.state), Curves.easeInOut.transform(_stateTransition.value))!;

  @override
  Widget build(BuildContext context) {
    // Lissage exponentiel simple : un niveau sonore brut « saute » d'une
    // trame à l'autre, l'orbe doit onduler plutôt que trembler.
    _smoothedLevel = _smoothedLevel * 0.7 + widget.level.clamp(0.0, 1.0) * 0.3;

    return AnimatedBuilder(
      animation: Listenable.merge([_breathController, _swirlController, _stateTransition]),
      builder: (context, _) {
        final breath = Curves.easeInOut.transform(_breathController.value);
        final reactive = widget.state == VoiceOrbState.idle ? breath * 0.5 : _smoothedLevel;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _VoiceOrbPainter(
              colors: _currentColors,
              glow: _currentGlow,
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

    // Halo extérieur — un bloom doux et large, jamais un anneau net : c'est
    // la lueur d'ambiance qui donne à la sphère l'impression de baigner
    // dans sa propre lumière, pas un cadre qui la découpe.
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [glow.withValues(alpha: 0.22 + intensity * 0.18), glow.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 2.4));
    canvas.drawCircle(center, radius * 2.4, haloPaint);

    // La source de lumière dérive très légèrement en orbite (au lieu de
    // rester rigoureusement fixe) : un soupçon de vie liquide sans jamais
    // se lire comme des « taches » distinctes qui tournent.
    final driftAngle = -2.35 + math.sin(swirl * 2 * math.pi) * 0.16;
    final lightCenter = center + Offset(math.cos(driftAngle), math.sin(driftAngle)) * radius * 0.42;

    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));

    // Corps de la sphère : UN SEUL dégradé radial décentré (lumière en
    // haut-gauche, ombre profonde en bas-droite), façon perle de verre —
    // plus lisible et plus premium qu'une texture de nappes en rotation.
    final sphereRect = Rect.fromCircle(center: center, radius: radius * 1.7);
    final spherePaint = Paint()
      ..shader = ui.Gradient.radial(
        lightCenter,
        radius * 1.85,
        [colors[0], colors[1], colors[2], colors[3]],
        const [0.0, 0.32, 0.62, 1.0],
      );
    canvas.drawRect(sphereRect, spherePaint);

    // Voile de teinte très doux, en excentricité opposée, pour une
    // profondeur de verre supplémentaire sans jamais dominer le dégradé
    // principal.
    final tintPaint = Paint()
      ..blendMode = BlendMode.softLight
      ..shader = ui.Gradient.radial(
        center - Offset(math.cos(driftAngle), math.sin(driftAngle)) * radius * 0.5,
        radius * 1.4,
        [colors[3].withValues(alpha: 0.5), colors[3].withValues(alpha: 0)],
      );
    canvas.drawCircle(center, radius, tintPaint);

    // Lumière spéculaire : un point net et brillant, légèrement plus haut
    // que le centre de lumière du dégradé — le détail qui vend le « verre
    // poli » plutôt qu'un disque mat.
    final specularCenter = lightCenter - Offset(radius * 0.08, radius * 0.1);
    canvas.drawCircle(
      specularCenter,
      radius * (0.16 + intensity * 0.03),
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withValues(alpha: 0.85), Colors.white.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: specularCenter, radius: radius * 0.32)),
    );

    canvas.restore();

    // Filet de bord à peine perceptible — sépare la sphère du fond sans
    // jamais se lire comme un contour dessiné.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.16),
    );
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
