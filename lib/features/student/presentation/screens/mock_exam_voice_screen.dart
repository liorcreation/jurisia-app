import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../theme/app_theme.dart';
import '../../../../core/exam/exam_voice_unlock.dart';
import '../../../../core/widgets/glass_container.dart';
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

  /// Chrome, en écoute continue (`continuous: true`, nécessaire pour capter
  /// des réponses de plusieurs phrases), ne déclenche pas de façon fiable
  /// de résultat "final" — vu en vidéo : un étudiant qui a fini de répondre
  /// ("c'est la loi qui doit primer") reste bloqué sur "Je vous écoute..."
  /// jusqu'à épuisement des 45 s, sans jamais avancer. Plutôt que d'attendre
  /// un signal du navigateur qui n'arrive pas toujours, on détecte
  /// nous-mêmes la fin de la réponse : si la transcription ne change plus
  /// pendant ce délai (l'étudiant s'est tu), on considère la réponse
  /// terminée et on valide automatiquement — le même principe que ChatGPT
  /// Voice Mode ou n'importe quel assistant vocal.
  static const _silenceAfterAnswerDuration = Duration(milliseconds: 2200);

  /// Chrome a un bug connu et documenté : `speechSynthesis.speak()` peut
  /// rester bloqué indéfiniment sans jamais émettre de son ni déclencher
  /// `onend` (silencieux, sans erreur) quand le navigateur choisit une voix
  /// réseau plutôt que locale — flutter_tts ne permet pas de forcer une
  /// voix locale sur web. Un délai de repli garantit que l'épreuve ne reste
  /// jamais figée si ce bug se produit.
  ///
  /// Un délai FIXE s'est révélé trop court pour les consignes les plus
  /// longues (ex. le message d'accueil) : la synthèse vocale réelle prenait
  /// plus longtemps à se terminer que les 20 s fixées, et le délai coupait
  /// la voix en pleine phrase avant d'enchaîner sur l'étape suivante — vu en
  /// vidéo, ça donne l'impression que « l'IA s'arrête subitement de
  /// parler ». Utiliser [_speakTimeoutFor] à la place, qui dimensionne le
  /// délai sur la longueur du texte à prononcer. Ce délai fixe reste utilisé
  /// tel quel pour les quelques appels courts sans texte à mesurer
  /// (awaitSpeakCompletion, setLanguage, stt.initialize).
  static const _speakTimeout = Duration(seconds: 20);

  /// Délai de sécurité pour la synthèse d'un texte donné : ~2 mots/seconde
  /// (rythme de parole lent, marge incluse) plus une marge fixe pour le
  /// démarrage du moteur — borné pour rester un vrai filet de sécurité
  /// (jamais en dessous de [_speakTimeout], jamais au-delà d'une minute).
  Duration _speakTimeoutFor(String text) {
    final wordCount = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final estimated = Duration(seconds: (wordCount / 2).ceil() + 6);
    if (estimated < _speakTimeout) return _speakTimeout;
    if (estimated > const Duration(seconds: 60)) return const Duration(seconds: 60);
    return estimated;
  }

  final FlutterTts _tts = FlutterTts();

  /// Non `final` : une toute NOUVELLE instance est créée avant chaque
  /// question (voir [_listenForAnswer]). `SpeechToText.initialize()` est un
  /// no-op silencieux une fois déjà initialisé (`if (_initWorked) return;`
  /// dans le package) — impossible donc de réinitialiser proprement le
  /// moteur sous-jacent via la même instance. Or vu en vidéo : la réponse
  /// de la question 2 dupliquait mot pour mot celle de la question 1 — un
  /// résultat tardif de l'ancienne session `webkitSpeechRecognition`
  /// (réutilisée d'une question à l'autre) arrivait après le redémarrage et
  /// contaminait la nouvelle. Une instance fraîche par question élimine
  /// toute possibilité qu'un évènement tardif d'une session précédente soit
  /// livré à la mauvaise question.
  SpeechToText _stt = SpeechToText();
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
  Timer? _autoConfirmTimer;

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
    // Diagnostic uniquement : le moteur web n'échoue pas silencieusement
    // sans raison — capter le message réel (ex. "not-allowed" quand Chrome
    // bloque la synthèse faute d'activation utilisateur) permet de le voir
    // dans la console au lieu qu'il soit avalé par nos try/catch en aval.
    _tts.setErrorHandler((message) => debugPrint('[voice-exam] tts onError: $message'));
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
    } catch (e) {
      // Sans conséquence si indisponible : _speak() reste protégé par son
      // propre délai de sécurité plus bas.
      debugPrint('[voice-exam] tts bootstrap (voices/language) failed: $e');
    }
    try {
      _sttAvailable = await _stt
          .initialize(
            onStatus: _onSttStatus,
            onError: (e) => debugPrint('[voice-exam] stt onError: $e'),
          )
          .timeout(_speakTimeout);
    } catch (e) {
      debugPrint('[voice-exam] stt initialize failed: $e');
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
    } catch (e) {
      // Sans conséquence : au pire la file de synthèse n'est pas purgée.
      debugPrint('[voice-exam] tts.stop() failed: $e');
    }
    try {
      await _tts.speak(text).timeout(_speakTimeoutFor(text));
    } catch (e) {
      // Repli silencieux (délai dépassé, TTS indisponible) : l'étudiant lit
      // la question déjà affichée dans le transcript, l'épreuve continue.
      debugPrint('[voice-exam] tts.speak() failed: $e');
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
    if (_sttAvailable) {
      await _listenForAnswer();
    } else {
      setState(() => _phase = _VoicePhase.typingFallback);
    }
  }

  /// Écoute de la réponse à la question courante, en UNE seule session de
  /// reconnaissance vocale continue plutôt que deux sessions successives
  /// (ancienne architecture : un court "silence check" dédié, arrêté, puis
  /// une seconde session d'écoute redémarrée juste après).
  ///
  /// La Web Speech API arrête la reconnaissance de façon ASYNCHRONE : un
  /// `stop()` ne fait que la demander, l'arrêt réel n'est confirmé que par
  /// l'évènement `onend` un instant plus tard — et ce délai s'est révélé peu
  /// fiable (vu en vidéo, avec la console ouverte : `InvalidStateError:
  /// recognition has already started` levé par le navigateur en rappelant
  /// `listen()` trop tôt, y compris après avoir attendu la confirmation
  /// `isListening == false`). Une seule session par question élimine ce
  /// redémarrage à chaud : les ~1,4 premières secondes servent de fenêtre de
  /// silence (détection de bruit armée, résultats ignorés), puis la même
  /// session continue pour capter la réponse — sans jamais rappeler
  /// `listen()` entre les deux.
  Future<void> _listenForAnswer() async {
    if (!_sttAvailable || !mounted) return;
    _autoConfirmTimer?.cancel();
    // Instance fraîche à chaque question (voir la doc du champ [_stt]) :
    // élimine toute chance qu'un résultat tardif d'une ancienne session
    // vienne contaminer la réponse de la nouvelle question.
    _stt.cancel();
    _stt = SpeechToText();
    try {
      final ready = await _stt
          .initialize(
            onStatus: _onSttStatus,
            onError: (e) => debugPrint('[voice-exam] stt onError: $e'),
          )
          .timeout(_speakTimeout);
      if (!ready) {
        if (mounted) setState(() => _phase = _VoicePhase.typingFallback);
        return;
      }
    } catch (e) {
      debugPrint('[voice-exam] stt re-initialize failed: $e');
      if (mounted) setState(() => _phase = _VoicePhase.typingFallback);
      return;
    }
    if (!mounted) return;
    setState(() {
      _phase = _VoicePhase.silenceCheck;
      _liveTranscript = '';
    });
    widget.controller.armNoiseGuard(true);
    var graceOver = false;
    final graceTimer = Timer(_silenceCheckDuration, () {
      widget.controller.armNoiseGuard(false);
      graceOver = true;
      if (!mounted || _answerConfirmed) return;
      setState(() => _phase = _VoicePhase.listening);
      _answerTimer
        ..reset()
        ..forward();
    });
    try {
      await _stt.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() => _liveTranscript = result.recognizedWords);
          if (!graceOver) return;
          // Ignore une réponse "finale" reçue pendant la fenêtre de
          // silence elle-même : à ce stade, l'étudiant n'est pas censé
          // avoir commencé à répondre.
          if (result.finalResult) {
            _confirmAnswer(result.recognizedWords);
            return;
          }
          // Le navigateur ne déclenche pas toujours ce résultat final en
          // écoute continue (voir doc de _silenceAfterAnswerDuration) :
          // (re)démarre un délai de silence à chaque changement de
          // transcription, qui valide la réponse de lui-même si l'étudiant
          // s'arrête de parler.
          _autoConfirmTimer?.cancel();
          if (result.recognizedWords.trim().isEmpty) return;
          _autoConfirmTimer = Timer(_silenceAfterAnswerDuration, () {
            if (!mounted || _answerConfirmed) return;
            _confirmAnswer(_liveTranscript);
          });
        },
        onSoundLevelChange: (level) {
          widget.controller.feedNoiseSample(level);
          if (!mounted || !graceOver) return;
          setState(() => _soundLevel = ((level + 2) / 12).clamp(0.0, 1.0));
        },
        listenOptions: SpeechListenOptions(partialResults: true, cancelOnError: true),
      );
    } catch (e) {
      debugPrint('[voice-exam] stt.listen() failed: $e');
      graceTimer.cancel();
      _autoConfirmTimer?.cancel();
      widget.controller.armNoiseGuard(false);
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
    _autoConfirmTimer?.cancel();
    _answerTimer.stop();
    final question = widget.controller.exam!.questions[_questionIndex];
    final trimmed = text.trim();
    widget.controller.answerCasPratique(question.id, trimmed);
    // cancel() (abort) plutôt que stop() : on a déjà la réponse, inutile de
    // laisser le moteur tenter de renvoyer un résultat final tardif, qui
    // pourrait sinon être livré après le début de la question suivante.
    unawaited(_stt.cancel().catchError((_) {}));
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
    _autoConfirmTimer?.cancel();
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
    _autoConfirmTimer?.cancel();
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
      child: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: _AmbientBackdrop())),
          SafeArea(
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
                  liveTranscript: _phase == _VoicePhase.listening ? _liveTranscript : '',
                ),
                const SizedBox(height: AppSpacing.md),
                _BottomBar(
                  isTyping: _phase == _VoicePhase.typingFallback,
                  sttAvailable: _sttAvailable,
                  soundLevel: _phase == _VoicePhase.listening ? _soundLevel : 0,
                  typedController: _typedController,
                  onSwitchToTyping: _switchToTyping,
                  onSubmitTyped: _submitTypedAnswer,
                  onQuit: _confirmQuit,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Toile de fond vivante : deux halos or/cobalt très sourds qui dérivent
/// lentement l'un vers l'autre en boucle, façon aurore discrète — donne à
/// l'obscurité immersive de l'épreuve une profondeur cinématographique au
/// lieu d'un simple aplat noir, sans jamais nuire à la lisibilité du
/// transcript ni rappeler un fond « chargé ».
class _AmbientBackdrop extends StatefulWidget {
  const _AmbientBackdrop();

  @override
  State<_AmbientBackdrop> createState() => _AmbientBackdropState();
}

class _AmbientBackdropState extends State<_AmbientBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _drift =
      AnimationController(vsync: this, duration: const Duration(seconds: 26))..repeat();

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, _) => CustomPaint(
        painter: _AmbientBackdropPainter(_drift.value),
        size: Size.infinite,
      ),
    );
  }
}

class _AmbientBackdropPainter extends CustomPainter {
  const _AmbientBackdropPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);

    void glow(Offset center, double radius, Color color) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [color.withValues(alpha: 0.16), color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    final a = (math.sin(t * 2 * math.pi) + 1) / 2;
    final b = (math.cos(t * 2 * math.pi * 0.7) + 1) / 2;

    glow(
      Offset(size.width * (0.18 + a * 0.12), size.height * (0.14 + b * 0.06)),
      size.width * 0.55,
      AppColors.gold,
    );
    glow(
      Offset(size.width * (0.86 - b * 0.14), size.height * (0.78 - a * 0.08)),
      size.width * 0.5,
      AppColors.cobalt,
    );
  }

  @override
  bool shouldRepaint(covariant _AmbientBackdropPainter oldDelegate) => oldDelegate.t != t;
}

/// Bannière d'alerte en verre dépoli — même langage visuel que
/// [GlassContainer], pour que même un message d'avertissement se sente
/// « fabriqué » plutôt qu'une alerte de navigateur générique.
class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.text, required this.onDismiss});

  final String text;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        borderColor: AppColors.warning.withValues(alpha: 0.45),
        borderRadius: AppRadius.medium,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.warning),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: AppColors.textPrimary, height: 1.4, fontSize: 12.5),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Piste de progression segmentée (une barre fine par question, remplie au
/// fil de l'épreuve) et médaillon caméra circulaire cerclé d'or avec point
/// « REC » pulsant — remplace le texte brut et la vignette carrée
/// d'origine par une signature visuelle propre à JurisIA.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.index, required this.total, required this.cameraController});

  final int index;
  final int total;
  final CameraController? cameraController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'QUESTION ${index + 1} / $total',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                    letterSpacing: AppLetterSpacing.caps,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (var i = 0; i < total; i++)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: i == total - 1 ? 0 : 4),
                          child: _ProgressSegment(state: i < index ? 2 : (i == index ? 1 : 0)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _CameraMedallion(controller: cameraController),
        ],
      ),
    );
  }
}

class _ProgressSegment extends StatelessWidget {
  const _ProgressSegment({required this.state});

  /// 0 = à venir, 1 = en cours, 2 = déjà répondue.
  final int state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      2 => AppColors.gold,
      1 => AppColors.goldLight,
      _ => AppColors.textSecondary.withValues(alpha: 0.22),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      height: 3.5,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: state == 1 ? AppShadows.goldGlowSoft : null,
      ),
    );
  }
}

class _CameraMedallion extends StatefulWidget {
  const _CameraMedallion({required this.controller});

  final CameraController? controller;

  @override
  State<_CameraMedallion> createState() => _CameraMedallionState();
}

class _CameraMedallionState extends State<_CameraMedallion> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 46.0;
    final active = widget.controller != null;

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(1.6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: active ? AppGradients.goldMetallic : null,
        color: active ? null : AppColors.textSecondary.withValues(alpha: 0.18),
        boxShadow: active ? AppShadows.goldGlowSoft : null,
      ),
      child: ClipOval(
        child: Container(
          color: AppColors.nightBlueDeep,
          child: Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: [
              if (active)
                FittedBox(fit: BoxFit.cover, child: SizedBox(width: 100, height: 100, child: CameraPreview(widget.controller!)))
              else
                const Icon(Icons.videocam_off_rounded, size: 16, color: AppColors.textDisabled),
              if (active)
                Positioned(
                  right: 3,
                  bottom: 3,
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) => Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.error.withValues(alpha: 0.55 + _pulse.value * 0.45),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.5 * _pulse.value),
                            blurRadius: 5,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fait apparaître chaque nouveau tour de parole en fondu + léger glissement
/// vers le haut plutôt qu'un simple `setState` sec — une conversation vocale
/// doit se sentir vivante jusque dans son défilement.
class _FadeInEntry extends StatefulWidget {
  const _FadeInEntry({required this.child});

  final Widget child;

  @override
  State<_FadeInEntry> createState() => _FadeInEntryState();
}

class _FadeInEntryState extends State<_FadeInEntry> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 380))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(curved),
        child: widget.child,
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
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black, Colors.black],
        stops: [0.0, 0.06, 1.0],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final entry = entries[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: _FadeInEntry(
              child: Align(
                alignment: entry.isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: entry.isUser ? _UserBubble(text: entry.text) : _AiTurn(text: entry.text),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AiTurn extends StatelessWidget {
  const _AiTurn({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (rect) => AppGradients.goldMetallic.createShader(rect),
                child: const Icon(Icons.auto_awesome_rounded, size: 13, color: Colors.white),
              ),
              const SizedBox(width: 6),
              Text(
                'JURISIA',
                style: TextStyle(
                  color: AppColors.goldLight.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5,
                  letterSpacing: AppLetterSpacing.caps,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(color: AppColors.textPrimary, height: 1.55, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gold.withValues(alpha: 0.22), AppColors.gold.withValues(alpha: 0.10)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45), width: 0.8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textPrimary, height: 1.45, fontSize: 14.5),
      ),
    );
  }
}

/// Scène de l'orbe : halo « sol » façon flaque de lumière pour lui donner
/// un ancrage plutôt qu'un vide, anneau de minuterie en dégradé graduée, et
/// transition douce du libellé d'état.
class _OrbArea extends StatelessWidget {
  const _OrbArea({
    required this.orbState,
    required this.soundLevel,
    required this.showRing,
    required this.ringRemaining,
    required this.animation,
    required this.liveTranscript,
  });

  final VoiceOrbState orbState;
  final double soundLevel;
  final bool showRing;
  final double ringRemaining;
  final Animation<double> animation;
  final String liveTranscript;

  Color get _stageGlow => switch (orbState) {
        VoiceOrbState.idle => AppColors.metalCobalt,
        VoiceOrbState.speaking => AppColors.gold,
        VoiceOrbState.listening => AppColors.cobalt,
        VoiceOrbState.thinking => AppColors.metalSilver,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                bottom: -18,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  child: Transform.scale(
                    scaleY: 0.3,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 34, sigmaY: 34),
                      child: Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [_stageGlow.withValues(alpha: 0.34), _stageGlow.withValues(alpha: 0)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (showRing)
                AnimatedBuilder(
                  animation: animation,
                  builder: (context, _) => SizedBox(
                    width: 208,
                    height: 208,
                    child: CustomPaint(painter: _AnswerRingPainter(ringRemaining)),
                  ),
                ),
              VoiceOrb(state: orbState, level: soundLevel, size: 176),
              Positioned(
                bottom: 6,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: KeyedSubtree(
                    key: ValueKey(orbState),
                    child: VoiceOrbStatusLabel(state: orbState),
                  ),
                ),
              ),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: liveTranscript.isEmpty
              ? const SizedBox(key: ValueKey('empty-live'), height: 0)
              : Padding(
                  key: const ValueKey('live'),
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
                  child: Text(
                    liveTranscript,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.85),
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Anneau de minuterie réduit à l'essentiel — un simple filet d'ombre en
/// fond et un arc en dégradé qui se consume, sans graduation ni ornement :
/// discret au point de presque disparaître derrière la sphère, jamais en
/// compétition avec elle.
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
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.06),
    );

    if (remaining <= 0) return;

    final urgent = remaining < 0.2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * remaining,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..shader = (urgent
                ? const LinearGradient(colors: [AppColors.error, Color(0xFFE0847F)])
                : const LinearGradient(colors: [AppColors.gold, AppColors.goldLight]))
            .createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(covariant _AnswerRingPainter oldDelegate) => oldDelegate.remaining != remaining;
}

/// Capsule de contrôle en verre dépoli — même signature que
/// [GlassContainer] — avec un mini vumètre animé pendant l'écoute plutôt
/// qu'une icône micro statique.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.isTyping,
    required this.sttAvailable,
    required this.soundLevel,
    required this.typedController,
    required this.onSwitchToTyping,
    required this.onSubmitTyped,
    required this.onQuit,
  });

  final bool isTyping;
  final bool sttAvailable;
  final double soundLevel;
  final TextEditingController typedController;
  final VoidCallback onSwitchToTyping;
  final VoidCallback onSubmitTyped;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.legalBlue.withValues(alpha: 0.4), AppColors.nightBlueDeep.withValues(alpha: 0.55)],
              ),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.glassBorder.withValues(alpha: 0.7), width: 0.7),
            ),
            child: Row(
              children: [
                if (isTyping) ...[
                  Expanded(
                    child: TextField(
                      controller: typedController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Tapez votre réponse…',
                        hintStyle: TextStyle(color: AppColors.textDisabled),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
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
                      icon: const Icon(Icons.keyboard_rounded, color: AppColors.textSecondary),
                      onPressed: onSwitchToTyping,
                      tooltip: 'Taper ma réponse',
                    ),
                  Expanded(child: Center(child: _MicLevelMeter(level: soundLevel))),
                ],
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: onQuit,
                  tooltip: 'Quitter',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mini vumètre à 5 barres, pic au centre, qui réagit au niveau sonore
/// capté — remplace l'icône micro statique par un signe de vie continu
/// pendant que l'étudiant parle.
class _MicLevelMeter extends StatelessWidget {
  const _MicLevelMeter({required this.level});

  final double level;

  static const _weights = [0.35, 0.65, 1.0, 0.65, 0.35];

  @override
  Widget build(BuildContext context) {
    final active = level > 0.02;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _weights.length; i++)
          Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 3),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              width: 3,
              height: 4 + (active ? level.clamp(0.0, 1.0) * 15 * _weights[i] : 0),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.cobalt.withValues(alpha: 0.9)
                    : AppColors.textSecondary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }
}
