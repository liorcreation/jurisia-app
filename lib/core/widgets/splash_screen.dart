import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'jurisia_mark.dart';
import 'luxury_scaffold_background.dart';

/// Écran de démarrage de JurisIA : la marque et le mot-symbole se révèlent
/// en fondu enchaîné, tiennent un instant, puis s'effacent au profit de
/// l'application — la première image que voit l'utilisateur, comme sur les
/// applications les plus abouties.
class JurisIASplashScreen extends StatefulWidget {
  const JurisIASplashScreen({super.key, required this.child});

  final Widget child;

  @override
  State<JurisIASplashScreen> createState() => _JurisIASplashScreenState();
}

class _JurisIASplashScreenState extends State<JurisIASplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _markOpacity;
  late final Animation<double> _markScale;
  late final Animation<double> _wordmarkOpacity;
  late final Animation<double> _fadeOut;

  bool _showApp = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

    _markOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.fastOutSlowIn),
    );
    _markScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
    );
    _wordmarkOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.30, 0.55, curve: Curves.fastOutSlowIn),
    );
    _fadeOut = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.82, 1.0, curve: Curves.fastOutSlowIn),
    );

    _controller.addStatusListener(_handleStatus);
    _controller.forward();
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _showApp = true);
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showApp) return widget.child;

    return LuxuryScaffoldBackground(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Opacity(
            opacity: 1 - _fadeOut.value,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: _markOpacity.value,
                    child: Transform.scale(
                      scale: 0.7 + 0.3 * _markScale.value,
                      child: const JurisIAMark(size: 76),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Opacity(
                    opacity: _wordmarkOpacity.value,
                    child: ShaderMask(
                      shaderCallback: (bounds) => AppGradients.goldMetallic.createShader(bounds),
                      child: Text(
                        'JurisIA',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              letterSpacing: AppLetterSpacing.headline,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
