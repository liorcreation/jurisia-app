import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache clé/valeur local (localStorage sur le Web, fichier natif ailleurs),
/// initialisé **une seule fois** au démarrage pour offrir des lectures
/// synchrones. C'est ce qui permet à la sidebar (historique des
/// consultations) et à la carte profil de s'afficher instantanément depuis
/// le dernier état connu, avant toute requête réseau, puis d'être
/// rafraîchies silencieusement en arrière-plan.
///
/// Tout est au mieux effort : si le stockage est indisponible (navigation
/// privée stricte, test sans binding), [instance] reste `null` et
/// l'application fonctionne normalement — simplement sans affichage
/// instantané au premier chargement.
class LocalCache {
  LocalCache._(this._prefs);

  final SharedPreferences _prefs;

  static LocalCache? _instance;

  /// `null` tant que [initialize] n'a pas réussi. Les appelants doivent
  /// dégrader proprement dans ce cas.
  static LocalCache? get instance => _instance;

  /// À appeler une fois, avant `runApp`, à côté des autres initialisations.
  static Future<void> initialize() async {
    if (_instance != null) return;
    try {
      _instance = LocalCache._(await SharedPreferences.getInstance());
    } catch (_) {
      // Stockage indisponible : on s'en passe.
    }
  }

  /// Lit et décode une valeur JSON. Renvoie `null` si absente ou illisible.
  T? readJson<T>(String key, T Function(Object? decoded) fromJson) {
    try {
      final raw = _prefs.getString(key);
      if (raw == null || raw.isEmpty) return null;
      return fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  /// Encode et écrit une valeur JSON. Au mieux effort, jamais bloquant pour
  /// l'appelant (le `Future` peut être ignoré sans risque).
  Future<void> writeJson(String key, Object? value) async {
    try {
      await _prefs.setString(key, jsonEncode(value));
    } catch (_) {
      // Écriture perdue : sans conséquence, le réseau reste la source de
      // vérité.
    }
  }

  Future<void> remove(String key) async {
    try {
      await _prefs.remove(key);
    } catch (_) {}
  }

  /// Réservé aux tests : force l'instance (ou la remet à zéro avec `null`).
  @visibleForTesting
  static void debugOverrideInstance(LocalCache? instance) => _instance = instance;
}
