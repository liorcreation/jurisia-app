import 'package:flutter/material.dart';

/// Fondu + glissement d'entrée, joué une seule fois à l'apparition du
/// widget — généralise le pattern déjà utilisé par `ChatBubble` (un
/// `AnimationController` par instance, lancé dans `initState`) pour
/// l'appliquer aux grilles/listes des modules : passez [index] et chaque
/// item démarre un peu après le précédent, pour un effet de cascade.
///
/// Le délai est plafonné à 12 items (voir [_maxStaggerIndex]) pour qu'une
/// longue liste (ex. les résultats de la bibliothèque) ne fasse pas
/// attendre les derniers éléments inutilement longtemps.
class EntranceFadeSlide extends StatefulWidget {
  const EntranceFadeSlide({
    super.key,
    required this.child,
    this.index = 0,
    this.stagger = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 420),
    this.offset = const Offset(0, 0.08),
  });

  final Widget child;
  final int index;
  final Duration stagger;
  final Duration duration;
  final Offset offset;

  static const int _maxStaggerIndex = 12;

  @override
  State<EntranceFadeSlide> createState() => _EntranceFadeSlideState();
}

class _EntranceFadeSlideState extends State<EntranceFadeSlide> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    final effectiveIndex = widget.index.clamp(0, EntranceFadeSlide._maxStaggerIndex);
    final delay = widget.stagger * effectiveIndex;
    if (delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn);

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(curved),
        child: widget.child,
      ),
    );
  }
}
