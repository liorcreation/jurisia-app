import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../theme/app_theme.dart';
import '../../../../core/widgets/voice_orb.dart';
import '../controllers/mock_exam_controller.dart';

class _ChatEntry {
  const _ChatEntry({required this.isUser, required this.text});

  final bool isUser;
  final String text;
}

enum _VoicePhase { aiSpeaking, silenceCheck, listening, reviewing, typingFallback }

/// Épreuve unique de l'examen blanc — une conversation vocale continue,
/// façon ChatGPT Voice Mode : l'IA énonce les consignes puis chaque
/// question à voix haute (TTS), l'étudiant répond oralement (STT) pendant
/// que l'orbe réagit au son, avec un repli clavier toujours accessible.
/// Remplace les trois anciens écrans de mode (QCM/écrit/oral), désormais
/// fusionnés en un seul format.
class MockExamVoiceBody extends StatefulWidget {
  const MockExamVoiceBody({super.key, required this.controller});

  final MockExamController controller;

  @override
  State<MockExamVoiceBody> createState() => _MockExamVoiceBodyState();
}

class _MockExamVoiceBodyState extends State<MockExamVoiceBody> with SingleTickerProviderStateMixin {
  static const _answerDuration = Duration(seconds: 45);
  static const _silenceCheckDuration = Duration(milliseconds: 1400);

  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();
  final TextEditingController _typedController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _answerTimer =
      AnimationController(vsync: this, duration: _answerDuration)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) _onAnswerTimeout();
        });

  bool _sttAvailable = false;
  int _questionIndex = 0;
  _VoicePhase _phase = _VoicePhase.aiSpeaking;
  double _soundLevel = 0;
  String _liveTranscript = '';
  bool _answerConfirmed = false;
  final List<_ChatEntry> _transcript = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _tts.awaitSpeakCompletion(true);
    try {
      _sttAvailable = await _stt.initialize(onStatus: _onSttStatus, onError: (_) {});
    } catch (_) {
      _sttAvailable = false;
    }
    if (!mounted) return;

    final total = widget.controller.exam!.questions.length;
    await _speak(
      "Bienvenue à votre examen blanc. Installez-vous dans un endroit calme, et "
      "positionnez votre appareil à la verticale, face à vous : votre caméra et "
      "votre micro restent actifs pendant toute l'épreuve. Je vais vous poser "
      '$total questions à voix haute ; répondez clairement après chacune. Vous '
      "pouvez à tout moment basculer sur la réponse écrite si besoin. C'est parti.",
    );
    if (!mounted) return;
    await _silenceCheck();
    if (!mounted) return;
    await _askCurrentQuestion();
  }

  Future<void> _speak(String text) async {
    if (!mounted) return;
    setState(() => _phase = _VoicePhase.aiSpeaking);
    _appendTranscript(isUser: false, text: text);
    try {
      await _tts.speak(text);
    } catch (_) {
      // Repli silencieux : l'étudiant lit la question affichée à l'écran.
    }
  }

  void _appendTranscript({required bool isUser, required String text}) {
    if (!mounted) return;
    setState(() => _transcript.add(_ChatEntry(isUser: isUser, text: text)));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  /// Courte fenêtre de silence, micro ouvert, entre la fin d'une consigne/
  /// question parlée et le début de l'écoute de la réponse — c'est le seul
  /// moment où la détection de bruit est armée (jamais pendant que l'IA
  /// parle elle-même, jamais pendant que l'étudiant répond).
  Future<void> _silenceCheck() async {
    if (!_sttAvailable || !mounted) return;
    setState(() => _phase = _VoicePhase.silenceCheck);
    widget.controller.armNoiseGuard(true);
    try {
      await _stt.listen(
        onResult: (_) {},
        onSoundLevelChange: (level) => widget.controller.feedNoiseSample(level),
        listenOptions: SpeechListenOptions(partialResults: false, cancelOnError: true),
      );
      await Future.delayed(_silenceCheckDuration);
      await _stt.stop();
    } catch (_) {
      // Silence check indisponible : sans conséquence, l'épreuve continue.
    }
    widget.controller.armNoiseGuard(false);
  }

  Future<void> _askCurrentQuestion() async {
    if (!mounted) return;
    final questions = widget.controller.exam!.questions;
    if (_questionIndex >= questions.length) {
      await widget.controller.submit();
      return;
    }
    _answerConfirmed = false;
    await _speak(questions[_questionIndex].statement);
    if (!mounted) return;
    await _silenceCheck();
    if (!mounted) return;
    if (_sttAvailable) {
      await _listen();
    } else {
      setState(() => _phase = _VoicePhase.typingFallback);
    }
  }

  Future<void> _listen() async {
    if (!mounted) return;
    setState(() {
      _phase = _VoicePhase.listening;
      _liveTranscript = '';
    });
    _answerTimer
      ..reset()
      ..forward();
    try {
      await _stt.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() => _liveTranscript = result.recognizedWords);
          if (result.finalResult) _confirmAnswer(result.recognizedWords);
        },
        onSoundLevelChange: (level) {
          if (!mounted) return;
          setState(() => _soundLevel = ((level + 2) / 12).clamp(0.0, 1.0));
        },
        listenOptions: SpeechListenOptions(partialResults: true, cancelOnError: true),
      );
    } catch (_) {
      if (mounted) setState(() => _phase = _VoicePhase.typingFallback);
    }
  }

  void _onSttStatus(String status) {
    if (!mounted) return;
    if (status == SpeechToText.doneStatus && _phase == _VoicePhase.listening && !_answerConfirmed) {
      if (_liveTranscript.trim().isNotEmpty) {
        _confirmAnswer(_liveTranscript);
      } else {
        _answerTimer.stop();
        setState(() => _phase = _VoicePhase.typingFallback);
      }
    }
  }

  void _onAnswerTimeout() {
    if (_phase != _VoicePhase.listening || _answerConfirmed) return;
    _confirmAnswer(_liveTranscript);
  }

  void _confirmAnswer(String text) {
    if (_answerConfirmed || !mounted) return;
    _answerConfirmed = true;
    _answerTimer.stop();
    final question = widget.controller.exam!.questions[_questionIndex];
    final trimmed = text.trim();
    widget.controller.answerCasPratique(question.id, trimmed);
    _stt.stop();
    _appendTranscript(isUser: true, text: trimmed.isEmpty ? '(pas de réponse)' : trimmed);
    setState(() => _phase = _VoicePhase.reviewing);

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      _questionIndex++;
      _askCurrentQuestion();
    });
  }

  void _submitTypedAnswer() {
    final text = _typedController.text.trim();
    if (text.isEmpty) return;
    _typedController.clear();
    _confirmAnswer(text);
  }

  void _switchToTyping() {
    _stt.cancel();
    _answerTimer.stop();
    setState(() => _phase = _VoicePhase.typingFallback);
  }

  Future<void> _confirmQuit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.legalBlueDark,
        title: const Text('Quitter l\'examen ?'),
        content: const Text('Votre progression sur cette tentative sera perdue.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) Navigator.of(context).maybePop();
  }

  VoiceOrbState get _orbState => switch (_phase) {
        _VoicePhase.aiSpeaking => VoiceOrbState.speaking,
        _VoicePhase.silenceCheck => VoiceOrbState.idle,
        _VoicePhase.listening => VoiceOrbState.listening,
        _VoicePhase.reviewing => VoiceOrbState.thinking,
        _VoicePhase.typingFallback => VoiceOrbState.idle,
      };

  @override
  void dispose() {
    _stt.cancel();
    _tts.stop();
    _answerTimer.dispose();
    _typedController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exam = widget.controller.exam!;
    final total = exam.questions.length;
    final cameraController = widget.controller.cameraGuard.previewController;

    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.black),
      child: SafeArea(
        child: Column(
          children: [
            _TopBar(
              index: math.min(_questionIndex, total - 1),
              total: total,
              cameraController: cameraController,
            ),
            Expanded(
              child: _transcript.isEmpty
                  ? const SizedBox.shrink()
                  : _TranscriptList(entries: _transcript, scrollController: _scrollController),
            ),
            _OrbArea(
              orbState: _orbState,
              soundLevel: _phase == _VoicePhase.listening ? _soundLevel : 0,
              showRing: _phase == _VoicePhase.listening,
              ringRemaining: 1 - _answerTimer.value,
              animation: _answerTimer,
            ),
            if (_phase == _VoicePhase.listening && _liveTranscript.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  _liveTranscript,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            _BottomBar(
              isTyping: _phase == _VoicePhase.typingFallback,
              sttAvailable: _sttAvailable,
              typedController: _typedController,
              onSwitchToTyping: _switchToTyping,
              onSubmitTyped: _submitTypedAnswer,
              onQuit: _confirmQuit,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.index, required this.total, required this.cameraController});

  final int index;
  final int total;
  final CameraController? cameraController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          Text(
            'Question ${index + 1} / $total',
            style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const Spacer(),
          if (cameraController != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(width: 44, height: 58, child: CameraPreview(cameraController!)),
            ),
        ],
      ),
    );
  }
}

class _TranscriptList extends StatelessWidget {
  const _TranscriptList({required this.entries, required this.scrollController});

  final List<_ChatEntry> entries;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final entry = entries[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Align(
            alignment: entry.isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: entry.isUser
                ? Container(
                    constraints: const BoxConstraints(maxWidth: 480),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 0.8),
                    ),
                    child: Text(
                      entry.text,
                      style: const TextStyle(color: Colors.white, height: 1.4),
                    ),
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Text(
                      entry.text,
                      style: const TextStyle(color: Colors.white70, height: 1.5),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _OrbArea extends StatelessWidget {
  const _OrbArea({
    required this.orbState,
    required this.soundLevel,
    required this.showRing,
    required this.ringRemaining,
    required this.animation,
  });

  final VoiceOrbState orbState;
  final double soundLevel;
  final bool showRing;
  final double ringRemaining;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showRing)
            AnimatedBuilder(
              animation: animation,
              builder: (context, _) => SizedBox(
                width: 208,
                height: 208,
                child: CustomPaint(painter: _AnswerRingPainter(ringRemaining)),
              ),
            ),
          VoiceOrb(state: orbState, level: soundLevel, size: 180),
          Positioned(
            bottom: 8,
            child: VoiceOrbStatusLabel(state: orbState),
          ),
        ],
      ),
    );
  }
}

class _AnswerRingPainter extends CustomPainter {
  const _AnswerRingPainter(this.remaining);

  final double remaining;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Colors.white.withValues(alpha: 0.08),
    );

    if (remaining <= 0) return;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * remaining,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = remaining < 0.2 ? AppColors.error : AppColors.goldLight.withValues(alpha: 0.75),
    );
  }

  @override
  bool shouldRepaint(covariant _AnswerRingPainter oldDelegate) => oldDelegate.remaining != remaining;
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.isTyping,
    required this.sttAvailable,
    required this.typedController,
    required this.onSwitchToTyping,
    required this.onSubmitTyped,
    required this.onQuit,
  });

  final bool isTyping;
  final bool sttAvailable;
  final TextEditingController typedController;
  final VoidCallback onSwitchToTyping;
  final VoidCallback onSubmitTyped;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            if (isTyping) ...[
              Expanded(
                child: TextField(
                  controller: typedController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Tapez votre réponse…',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => onSubmitTyped(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: AppColors.goldLight),
                onPressed: onSubmitTyped,
                tooltip: 'Envoyer',
              ),
            ] else ...[
              if (sttAvailable)
                IconButton(
                  icon: const Icon(Icons.keyboard_rounded, color: Colors.white70),
                  onPressed: onSwitchToTyping,
                  tooltip: 'Taper ma réponse',
                ),
              const Expanded(
                child: Center(child: Icon(Icons.mic_rounded, color: Colors.white38, size: 18)),
              ),
            ],
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white70),
              onPressed: onQuit,
              tooltip: 'Quitter',
            ),
          ],
        ),
      ),
    );
  }
}
