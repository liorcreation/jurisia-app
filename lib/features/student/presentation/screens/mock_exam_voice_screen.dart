import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../theme/app_theme.dart';
import '../../../../core/exam/exam_voice_unlock.dart';
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

  /// Chrome a un bug connu et documenté : `speechSynthesis.speak()` peut
  /// rester bloqué indéfiniment sans jamais émettre de son ni déclencher
  /// `onend` (silencieux, sans erreur) quand le navigateur choisit une voix
  /// réseau plutôt que locale — flutter_tts ne permet pas de forcer une
  /// voix locale sur web. Un délai généreux (largement au-dessus de la plus
  /// longue consigne réelle) garantit que l'épreuve ne reste jamais figée :
  /// à l'expiration, l'étudiant a déjà la question sous les yeux (transcript)
  /// et l'épreuve continue normalement sans le son.
  static const _speakTimeout = Duration(seconds: 20);

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

  /// `true` dès que la synthèse vocale a réellement émis un son au moins
  /// une fois (callback `onStart` du moteur natif/navigateur — un signal
  /// bien plus fiable que la simple résolution de `speak()`, qui peut se
  /// résoudre par notre propre délai de sécurité sans avoir rien joué).
  bool _ttsConfirmedWorking = false;

  /// Bannières affichées une fois, si la voix ou le micro se révèlent
  /// indisponibles — pour que l'étudiant comprenne pourquoi plutôt que de
  /// se retrouver démuni devant un écran silencieux.
  bool _showTtsWarning = false;
  bool _showMicWarning = false;

  @override
  void initState() {
    super.initState();
    _tts.setStartHandler(() => _ttsConfirmedWorking = true);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      // Sur Chromium (Chrome, Edge...), la liste des voix se charge de
      // façon asynchrone : un setLanguage()/speak() appelé avant qu'elle
      // ne soit prête peut échouer à trouver une voix et être abandonné
      // silencieusement.
      await waitForWebSpeechVoicesReady();
      await _tts.awaitSpeakCompletion(true).timeout(_speakTimeout);
      // Explicite plutôt que de laisser le navigateur retomber sur la
      // langue par défaut du système (pas forcément le français, et pas
      // forcément une langue pour laquelle une voix est installée).
      await _tts.setLanguage('fr-FR').timeout(_speakTimeout);
    } catch (_) {
      // Sans conséquence si indisponible : _speak() reste protégé par son
      // propre délai de sécurité plus bas.
    }
    try {
      _sttAvailable = await _stt.initialize(onStatus: _onSttStatus, onError: (_) {}).timeout(_speakTimeout);
    } catch (_) {
      _sttAvailable = false;
    }
    if (!mounted) return;
    if (!_sttAvailable) setState(() => _showMicWarning = true);

    final total = widget.controller.exam!.questions.length;
    await _speak(
      "Bienvenue à votre examen blanc. Installez-vous dans un endroit calme, et "
      "positionnez votre appareil à la verticale, face à vous : votre caméra et "
      "votre micro restent actifs pendant toute l'épreuve. Je vais vous poser "
      '$total questions à voix haute ; répondez clairement après chacune. Vous '
      "pouvez à tout moment basculer sur la réponse écrite si besoin. C'est parti.",
    );
    if (!mounted) return;
    if (!_ttsConfirmedWorking) setState(() => _showTtsWarning = true);
    await _silenceCheck();
    if (!mounted) return;
    await _askCurrentQuestion();
  }

  Future<void> _speak(String text) async {
    if (!mounted) return;
    setState(() => _phase = _VoicePhase.aiSpeaking);
    _appendTranscript(isUser: false, text: text);
    try {
      // Réinitialise un éventuel état bloqué du moteur vocal (utile sur
      // web, où le bug ci-dessus peut laisser la file de synthèse "coincée"
      // après une tentative précédente) avant de parler. Isolé dans son
      // propre try/catch : certaines implémentations web de flutter_tts ne
      // fournissent pas la méthode "stop" (MissingPluginException) — un
      // échec ici ne doit JAMAIS empêcher l'appel à speak() qui suit, sans
      // quoi aucun son n'est jamais émis.
      await _tts.stop();
    } catch (_) {
      // Sans conséquence : au pire la file de synthèse n'est pas purgée.
    }
    try {
      await _tts.speak(text).timeout(_speakTimeout);
    } catch (_) {
      // Repli silencieux (délai dépassé, TTS indisponible) : l'étudiant lit
      // la question déjà affichée dans le transcript, l'épreuve continue.
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
    unawaited(_stt.stop().catchError((_) {}));
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
    unawaited(_tts.stop().catchError((_) {}));
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
            if (_showTtsWarning)
              _WarningBanner(
                text: "Synthèse vocale indisponible sur ce navigateur — les questions restent "
                    'affichées ci-dessous, répondez au clavier ou à l\'oral si le micro fonctionne.',
                onDismiss: () => setState(() => _showTtsWarning = false),
              ),
            if (_showMicWarning)
              _WarningBanner(
                text: 'Réponse orale indisponible sur ce navigateur (certains, comme Edge, ne '
                    'la prennent pas en charge — essayez Chrome) ou micro non autorisé : '
                    'vérifiez les réglages du navigateur, ou répondez au clavier.',
                onDismiss: () => setState(() => _showMicWarning = false),
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

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.text, required this.onDismiss});

  final String text;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.small),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.4), width: 0.8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.warning),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(text, style: const TextStyle(color: Colors.white, height: 1.4, fontSize: 12.5)),
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close_rounded, size: 16, color: Colors.white70),
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
