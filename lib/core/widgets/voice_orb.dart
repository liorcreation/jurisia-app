import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// État courant de l'assistant vocal, chacun avec sa propre teinte : l'or de
/// la marque quand l'IA parle, un cobalt plus froid quand elle écoute,
/// neutre au repos ou en réflexion (correction en cours).
enum VoiceOrbState { idle, speaking, listening, thinking }

/// Orbe circulaire animé façon « Voice Mode » : respire doucement au repos,
/// et grossit/s'illumine en réaction au niveau sonore capté ([level], de 0 à
/// 1) pendant l'écoute ou la synthèse vocale.
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

class _VoiceOrbState extends State<VoiceOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _breathController =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);

  double _smoothedLevel = 0;

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  Color get _tint {
    switch (widget.state) {
      case VoiceOrbState.idle:
        return AppColors.metalCobalt;
      case VoiceOrbState.speaking:
        return AppColors.gold;
      case VoiceOrbState.listening:
        return AppColors.goldLight;
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
      animation: _breathController,
      builder: (context, _) {
        final breath = Curves.easeInOut.transform(_breathController.value);
        final reactive = widget.state == VoiceOrbState.idle ? breath * 0.5 : _smoothedLevel;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _VoiceOrbPainter(tint: _tint, intensity: reactive, breath: breath),
          ),
        );
      },
    );
  }
}

class _VoiceOrbPainter extends CustomPainter {
  const _VoiceOrbPainter({required this.tint, required this.intensity, required this.breath});

  final Color tint;
  final double intensity;
  final double breath;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final baseRadius = size.width / 2 * 0.52;
    final radius = baseRadius * (1 + intensity * 0.4);

    // Halo extérieur, d'autant plus large et diffus que le niveau sonore
    // est élevé.
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [tint.withValues(alpha: 0.32 + intensity * 0.25), tint.withValues(alpha: 0)],
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
        ..color = tint.withValues(alpha: (1 - ringPhase) * 0.22);
      canvas.drawCircle(center, ringRadius, ringPaint);
    }

    // Corps de l'orbe : dégradé métallique cohérent avec le reste du design
    // system, plus lumineux au centre.
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.9),
          tint,
          tint.withValues(alpha: 0.75),
        ],
        stops: const [0.0, 0.55, 1.0],
        center: const Alignment(-0.25, -0.3),
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, corePaint);

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: 0.35);
    canvas.drawCircle(center, radius, rimPaint);
  }

  @override
  bool shouldRepaint(covariant _VoiceOrbPainter oldDelegate) =>
      oldDelegate.tint != tint || oldDelegate.intensity != intensity || oldDelegate.breath != breath;
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
