/// Découpe un flux de texte reçu fragment par fragment en une partie
/// visible (tout ce qui précède le premier marqueur d'ouverture) et un bloc
/// caché accumulé à partir de ce marqueur, en gérant le cas où le marqueur
/// lui-même est fragmenté entre deux paquets du flux source.
///
/// Utilisé pour séparer la réponse visible d'une IA d'un bloc de données
/// structurées (JSON) qu'elle ajoute en fin de réponse mais qui ne doit
/// jamais être affiché à l'utilisateur.
class HiddenBlockStreamSplitter {
  HiddenBlockStreamSplitter({required this.markerStart});

  final String markerStart;

  final StringBuffer visibleAccumulated = StringBuffer();
  final StringBuffer hidden = StringBuffer();

  bool _markerFound = false;
  String _pending = '';

  bool get markerFound => _markerFound;

  /// Traite un nouveau fragment reçu du flux ; retourne la portion visible
  /// nouvellement disponible (peut être vide), à afficher immédiatement.
  String feed(String delta) {
    if (_markerFound) {
      hidden.write(delta);
      return '';
    }

    _pending += delta;
    final idx = _pending.indexOf(markerStart);
    if (idx != -1) {
      final visiblePart = _pending.substring(0, idx);
      if (visiblePart.isNotEmpty) visibleAccumulated.write(visiblePart);
      hidden.write(_pending.substring(idx));
      _markerFound = true;
      _pending = '';
      return visiblePart;
    }

    final safeLen = _pending.length - (markerStart.length - 1);
    if (safeLen > 0) {
      final safePart = _pending.substring(0, safeLen);
      visibleAccumulated.write(safePart);
      _pending = _pending.substring(safeLen);
      return safePart;
    }
    return '';
  }

  /// À appeler une fois le flux source terminé : purge un éventuel reliquat
  /// non encore émis (cas où le marqueur n'a jamais été trouvé). Retourne
  /// ce reliquat, à afficher le cas échéant.
  String flush() {
    if (!_markerFound && _pending.isNotEmpty) {
      final remaining = _pending;
      visibleAccumulated.write(remaining);
      _pending = '';
      return remaining;
    }
    return '';
  }
}
