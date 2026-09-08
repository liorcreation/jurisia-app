import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/voice_orb.dart';
import '../../../../theme/app_theme.dart';
import '../controllers/mock_exam_controller.dart';

enum _OralPhase { preparing, speakingQuestion, listening, reviewing, typingFallback }

/// Mode C — Examen oral (Voice Mode) : l'IA énonce chaque question à voix
/// haute (TTS), l'étudiant répond oralement (STT) pendant que l'orbe réagit
/// au niveau sonore, avec un repli de saisie manuelle toujours accessible si
/// la reconnaissance vocale échoue ou n'est pas supportée.
///
/// Ne comporte volontairement AUCUNE consigne de positionnement caméra : la
/// détection de mouvement/mains par caméra est un chantier séparé, non
/// construit dans cette passe (voir le plan) — instruire l'étudiant à ce
/// sujet mentirait sur une surveillance qui n'existe pas encore.
class MockExamOralBody extends StatefulWidget {
  const MockExamOralBody({super.key, required this.controller});

  final MockExamController controller;

  @override
  State<MockExamOralBody> createState() => _MockExamOralBodyState();
}

class _MockExamOralBodyState extends State<MockExamOralBody> {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();
  final TextEditingController _typedController = TextEditingController();

  bool _sttAvailable = false;
  int _questionIndex = 0;
  _OralPhase _phase = _OralPhase.preparing;
  double _soundLevel = 0;
  String _liveTranscript = '';
  bool _answerConfirmed = false;

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
    await _speak(
      "Bienvenue à votre examen oral. Installez-vous dans un endroit calme. "
      "Je vais énoncer chaque question à voix haute ; répondez clairement après le signal. "
      "Vous pouvez à tout moment basculer sur la réponse écrite si besoin.",
    );
    await _askCurrentQuestion();
  }

  Future<void> _speak(String text) async {
    if (!mounted) return;
    setState(() => _phase = _OralPhase.speakingQuestion);
    try {
      await _tts.speak(text);
    } catch (_) {
      // Repli silencieux : l'étudiant lit la question affichée à l'écran.
    }
  }

  Future<void> _askCurrentQuestion() async {
    final questions = widget.controller.exam!.questions;
    if (_questionIndex >= questions.length) {
      await widget.controller.submit();
      return;
    }
    _answerConfirmed = false;
    await _speak(questions[_questionIndex].statement);
    if (!mounted) return;
    if (_sttAvailable) {
      await _listen();
    } else {
      setState(() => _phase = _OralPhase.typingFallback);
    }
  }

  Future<void> _listen() async {
    setState(() {
      _phase = _OralPhase.listening;
      _liveTranscript = '';
    });
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
      if (mounted) setState(() => _phase = _OralPhase.typingFallback);
    }
  }

  void _onSttStatus(String status) {
    if (!mounted) return;
    if (status == SpeechToText.doneStatus && _phase == _OralPhase.listening && !_answerConfirmed) {
      if (_liveTranscript.trim().isNotEmpty) {
        _confirmAnswer(_liveTranscript);
      } else {
        setState(() => _phase = _OralPhase.typingFallback);
      }
    }
  }

  void _confirmAnswer(String text) {
    if (_answerConfirmed) return;
    _answerConfirmed = true;
    final question = widget.controller.exam!.questions[_questionIndex];
    widget.controller.answerCasPratique(question.id, text.trim());
    _stt.stop();
    if (!mounted) return;
    setState(() => _phase = _OralPhase.reviewing);
  }

  void _submitTypedAnswer() {
    final text = _typedController.text.trim();
    if (text.isEmpty) return;
    final question = widget.controller.exam!.questions[_questionIndex];
    widget.controller.answerCasPratique(question.id, text);
    _typedController.clear();
    _answerConfirmed = true;
    setState(() => _phase = _OralPhase.reviewing);
  }

  void _switchToTyping() {
    _stt.cancel();
    setState(() => _phase = _OralPhase.typingFallback);
  }

  Future<void> _nextQuestion() async {
    _questionIndex++;
    await _askCurrentQuestion();
  }

  VoiceOrbState get _orbState => switch (_phase) {
        _OralPhase.speakingQuestion => VoiceOrbState.speaking,
        _OralPhase.listening => VoiceOrbState.listening,
        _OralPhase.reviewing => VoiceOrbState.thinking,
        _ => VoiceOrbState.idle,
      };

  @override
  void dispose() {
    _stt.cancel();
    _tts.stop();
    _typedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final questions = widget.controller.exam!.questions;
    final total = questions.length;
    final isLast = _questionIndex >= total - 1;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Stack(
                children: [
                  Container(height: 5, color: AppColors.legalBlueDark),
                  FractionallySizedBox(
                    widthFactor: total == 0 ? 0.001 : ((_questionIndex + 1) / total).clamp(0.001, 1.0),
                    child: Container(height: 5, decoration: const BoxDecoration(gradient: AppGradients.goldMetallic)),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Question ${_questionIndex + 1} / $total',
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.goldLight,
                          letterSpacing: AppLetterSpacing.label,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      VoiceOrb(state: _orbState, level: _phase == _OralPhase.listening ? _soundLevel : 0),
                      const SizedBox(height: AppSpacing.lg),
                      VoiceOrbStatusLabel(state: _orbState),
                      const SizedBox(height: AppSpacing.xl),
                      if (_phase != _OralPhase.typingFallback)
                        GlassContainer(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            questions[_questionIndex].statement,
                            textAlign: TextAlign.center,
                            style: textTheme.titleMedium?.copyWith(fontFamily: 'Libre Caslon Display', height: 1.4),
                          ),
                        ),
                      if (_phase == _OralPhase.listening && _liveTranscript.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          _liveTranscript,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                        ),
                      ],
                      if (_phase == _OralPhase.reviewing) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                            const SizedBox(width: AppSpacing.sm),
                            Text('Réponse enregistrée', style: textTheme.bodyMedium?.copyWith(color: AppColors.success)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton.icon(
                          onPressed: isLast ? () => widget.controller.submit() : _nextQuestion,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: AppColors.nightBlueDeep,
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 13),
                          ),
                          icon: Icon(isLast ? Icons.done_all_rounded : Icons.arrow_forward_rounded, size: 17),
                          label: Text(isLast ? "Rendre l'examen" : 'Question suivante'),
                        ),
                      ],
                      if (_phase == _OralPhase.typingFallback) ...[
                        const SizedBox(height: AppSpacing.lg),
                        TextField(
                          controller: _typedController,
                          maxLines: 4,
                          style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
                          decoration: const InputDecoration(hintText: 'Tapez votre réponse ici…'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton.icon(
                          onPressed: _submitTypedAnswer,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: AppColors.nightBlueDeep,
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 13),
                          ),
                          icon: const Icon(Icons.check_rounded, size: 17),
                          label: const Text('Valider ma réponse'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_phase == _OralPhase.listening || _phase == _OralPhase.speakingQuestion)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: TextButton.icon(
                onPressed: _switchToTyping,
                icon: const Icon(Icons.keyboard_rounded, size: 16),
                label: const Text('Taper ma réponse à la place'),
              ),
            ),
        ],
      ),
    );
  }
}
