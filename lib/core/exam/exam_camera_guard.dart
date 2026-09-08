import 'dart:async';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import 'exam_camera_support.dart';

/// Détection de mouvement/présence par différence d'image, via des photos
/// périodiques de la caméra frontale plutôt qu'un flux continu — nécessaire
/// pour rester uniforme avec Windows (`camera_windows`, dépendance non
/// endorsée ajoutée explicitement, qui ne supporte pas le flux d'image en
/// continu). Aucune photo n'est conservée ni transmise : chaque image est
/// réduite à une minuscule vignette en niveaux de gris en mémoire, comparée
/// à la précédente, puis immédiatement jetée.
///
/// Volontairement simple : une différence de luminance globale entre deux
/// images successives, pas de reconnaissance faciale ni de suivi des mains
/// (hors de portée ici) — détecte une sortie de cadre, un changement de
/// personne ou une agitation soutenue, pas des gestes précis.
///
/// Non disponible sur macOS (aucune implémentation caméra Flutter fiable et
/// vérifiable dans cet environnement — voir pubspec.yaml) ni sur le web :
/// [start] renvoie alors simplement `false` sans planter, l'épreuve continue
/// sans ce signal plutôt que de bloquer l'étudiant pour une raison
/// d'infrastructure.
class ExamCameraGuard {
  ExamCameraGuard({required this.onDisqualified});

  final VoidCallback onDisqualified;

  static const Duration _sampleInterval = Duration(milliseconds: 1200);
  static const int _thumbnailSize = 24;

  /// Différence moyenne de luminance (0-255) au-delà de laquelle deux
  /// images successives sont jugées "très différentes". Seuil de première
  /// approche, à affiner sur de vrais appareils.
  static const double _diffThreshold = 28;

  /// Échantillons consécutifs au-dessus du seuil avant disqualification.
  static const int _consecutiveTrigger = 3;

  CameraController? _controller;
  Timer? _timer;
  Uint8List? _lastThumbnail;
  int _consecutiveHits = 0;
  bool _disqualified = false;
  bool _sampling = false;

  bool get isSupported => isCameraGuardSupportedPlatform;

  /// Contrôleur à rendre dans un `CameraPreview` (aperçu discret, transparent
  /// envers l'étudiant) une fois prêt — `null` tant que la caméra n'est pas
  /// initialisée ou non supportée sur cette plateforme.
  CameraController? get previewController => (_controller?.value.isInitialized ?? false) ? _controller : null;

  /// Démarre le proctoring caméra ; renvoie `false` (sans exception) si la
  /// plateforme n'est pas supportée, si aucune caméra n'est disponible ou si
  /// la permission est refusée — jamais un blocage de l'épreuve pour une
  /// raison d'infrastructure.
  Future<bool> start() async {
    if (!isSupported) return false;
    try {
      // Délai maximal : un canal caméra natif absent ou bloqué (permission
      // jamais accordée ni refusée, plateforme de test sans implémentation)
      // ne doit jamais laisser l'épreuve en attente indéfiniment.
      final cameras = await availableCameras().timeout(const Duration(seconds: 6));
      if (cameras.isEmpty) return false;

      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(front, ResolutionPreset.low, enableAudio: false);
      await controller.initialize().timeout(const Duration(seconds: 6));
      _controller = controller;
      _timer = Timer.periodic(_sampleInterval, (_) => _sample());
      return true;
    } catch (_) {
      await stop();
      return false;
    }
  }

  Future<void> _sample() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _disqualified || _sampling) return;
    _sampling = true;
    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      final thumbnail = await _toGrayscaleThumbnail(bytes);
      final previous = _lastThumbnail;
      _lastThumbnail = thumbnail;
      if (previous == null || thumbnail.isEmpty || previous.length != thumbnail.length) return;

      var totalDiff = 0;
      for (var i = 0; i < thumbnail.length; i++) {
        totalDiff += (thumbnail[i] - previous[i]).abs();
      }
      final meanDiff = totalDiff / thumbnail.length;

      if (meanDiff > _diffThreshold) {
        _consecutiveHits++;
        if (_consecutiveHits >= _consecutiveTrigger) {
          _disqualified = true;
          onDisqualified();
        }
      } else {
        _consecutiveHits = 0;
      }
    } catch (_) {
      // Un échec ponctuel de capture (mise au point, verrou natif) ne doit
      // jamais faire échouer l'examen — on retente au prochain intervalle.
    } finally {
      _sampling = false;
    }
  }

  Future<Uint8List> _toGrayscaleThumbnail(Uint8List imageBytes) async {
    final codec = await ui.instantiateImageCodec(
      imageBytes,
      targetWidth: _thumbnailSize,
      targetHeight: _thumbnailSize,
    );
    final frame = await codec.getNextFrame();
    final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
    frame.image.dispose();
    if (byteData == null) return Uint8List(0);

    final rgba = byteData.buffer.asUint8List();
    final gray = Uint8List(rgba.length ~/ 4);
    for (var i = 0; i < gray.length; i++) {
      final o = i * 4;
      gray[i] = ((rgba[o] + rgba[o + 1] + rgba[o + 2]) / 3).round();
    }
    return gray;
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _lastThumbnail = null;
    _consecutiveHits = 0;
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      try {
        await controller.dispose();
      } catch (_) {}
    }
  }
}
