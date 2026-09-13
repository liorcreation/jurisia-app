import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/voice_orb.dart';
import '../../../../theme/app_theme.dart';
import '../controllers/evaluation_controller.dart';

/// Conversation orale d'une évaluation de module. La question est prononcée,
/// la réponse est transcrite, et un champ clavier reste toujours disponible
/// lorsque le navigateur ou le périphérique refuse l'accès vocal.
class VoiceEvaluationView extends StatefulWidget {
  const VoiceEvaluationView({super.key, required this.controller});

  final EvaluationController controller;

  @override
  State<VoiceEvaluationView> createState() => _VoiceEvaluationViewState();
}

class _VoiceEvaluationViewState extends State<VoiceEvaluationView> {
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _typedController = TextEditingController();
  final SpeechToText _stt = SpeechToText();
  Timer? _answerTimeout;
  Timer? _silenceTimer;
  Timer? _acousticWindowTimer;

  int _index = 0;
  String _transcript = '';
  double _soundLevel = 0;
  bool _sttAvailable = false;
  bool _busy = false;
  VoiceOrbState _orbState = VoiceOrbState.idle;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    unawaited(_bootstrap());
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _bootstrap() async {
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('fr-FR');
    } catch (_) {}
    try {
      _sttAvailable = await _stt.initialize(
        onStatus: (status) {
          if (status == SpeechToText.doneStatus &&
              mounted &&
              _orbState == VoiceOrbState.listening) {
            _confirmAnswer();
          }
        },
        onError: (_) {},
      );
    } catch (_) {
      _sttAvailable = false;
    }
    if (!mounted) return;
    setState(() {});
    await _askCurrentQuestion();
  }

  Future<void> _askCurrentQuestion() async {
    if (!mounted || widget.controller.isSubmitted) return;
    final questions = widget.controller.evaluation?.questions ?? const [];
    if (_index >= questions.length) {
      widget.controller.submit();
      return;
    }
    _busy = true;
    _transcript = '';
    _typedController.clear();
    await _speak(questions[_index].statement);
    if (!mounted) return;
    _busy = false;
    if (_sttAvailable) {
      await _listenForAnswer();
    } else {
      setState(() => _orbState = VoiceOrbState.idle);
    }
  }

  Future<void> _speak(String text) async {
    if (!mounted) return;
    widget.controller.armNoiseGuard(false);
    setState(() => _orbState = VoiceOrbState.speaking);
    try {
      await _tts.stop();
      await _tts.speak(text).timeout(const Duration(seconds: 30));
    } catch (_) {}
  }

  Future<void> _listenForAnswer() async {
    if (!mounted) return;
    _answerTimeout?.cancel();
    _silenceTimer?.cancel();
    _acousticWindowTimer?.cancel();
    widget.controller.armNoiseGuard(false);
    widget.controller.armNoiseGuard(true);
    _acousticWindowTimer = Timer(
      const Duration(milliseconds: 1400),
      () => widget.controller.armNoiseGuard(false),
    );
    setState(() => _orbState = VoiceOrbState.listening);
    try {
      await _stt.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() => _transcript = result.recognizedWords);
          _silenceTimer?.cancel();
          _silenceTimer = Timer(
            const Duration(milliseconds: 2200),
            _confirmAnswer,
          );
          if (result.finalResult) _confirmAnswer();
        },
        onSoundLevelChange: (level) {
          widget.controller.feedNoiseSample(level);
          if (mounted) {
            setState(() => _soundLevel = ((level + 2) / 12).clamp(0.0, 1.0));
          }
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _sttAvailable = false);
    }
    _answerTimeout = Timer(const Duration(seconds: 45), _confirmAnswer);
  }

  void _confirmAnswer() {
    if (!mounted || _busy || widget.controller.isSubmitted) return;
    final text = _transcript.trim();
    if (text.isEmpty) {
      setState(() => _orbState = VoiceOrbState.idle);
      return;
    }
    _submitAnswer(text);
  }

  void _submitTypedAnswer() {
    final text = _typedController.text.trim();
    if (text.isNotEmpty) _submitAnswer(text);
  }

  void _submitAnswer(String text) {
    if (_busy) return;
    _busy = true;
    _answerTimeout?.cancel();
    _silenceTimer?.cancel();
    _acousticWindowTimer?.cancel();
    widget.controller.armNoiseGuard(false);
    _stt.stop();
    widget.controller.answerCasPratique(
      widget.controller.evaluation!.questions[_index].id,
      text,
    );
    if (mounted) setState(() => _orbState = VoiceOrbState.thinking);
    Future<void>.delayed(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      final total = widget.controller.evaluation?.questions.length ?? 0;
      if (_index >= total - 1) {
        widget.controller.submit();
        return;
      }
      _index++;
      _busy = false;
      unawaited(_askCurrentQuestion());
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _answerTimeout?.cancel();
    _silenceTimer?.cancel();
    _acousticWindowTimer?.cancel();
    unawaited(_tts.stop());
    unawaited(_stt.stop());
    _typedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.controller.evaluation!.questions[_index];
    final camera = widget.controller.cameraPreviewController;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Row(
                children: [
                  _VoiceModeBadge(),
                  const Spacer(),
                  Text(
                    '${_index + 1} / ${widget.controller.evaluation!.questions.length}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              GlassContainer(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    VoiceOrb(state: _orbState, level: _soundLevel, size: 220),
                    const SizedBox(height: AppSpacing.sm),
                    VoiceOrbStatusLabel(state: _orbState),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      question.statement,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (_transcript.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        '« $_transcript »',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.goldLight,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: _typedController,
                      minLines: 2,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Réponse écrite de secours',
                        hintText: 'Si nécessaire, rédigez votre réponse ici…',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      onPressed: _busy ? null : _submitTypedAnswer,
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Valider la réponse'),
                    ),
                  ],
                ),
              ),
              if (camera != null) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 96,
                  width: 128,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    child: CameraPreview(camera),
                  ),
                ),
              ],
              if (!_sttAvailable) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Micro indisponible : la saisie clavier reste active.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.warning),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceModeBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          'VOICE MODE',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.goldLight),
        ),
      ),
    );
  }
}
