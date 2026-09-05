import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_ai_prompt.dart';
import 'admin_prompt_repository.dart';

/// État de l'écran « Studio de prompts » : la liste des prompts (regroupés
/// par clé côté écran), et les actions rédiger / tester / publier. Les
/// messages d'erreur du serveur (jamais testé, réservé aux super
/// administrateurs…) sont déjà en français et actionnables — affichés tels
/// quels.
class AdminPromptController extends ChangeNotifier {
  AdminPromptController({required this.repository}) {
    // ignore: unawaited_futures
    load();
  }

  final AdminPromptRepository repository;

  List<AdminAiPrompt> _prompts = const [];
  bool _loading = false;
  bool _mutating = false;
  String? _error;

  bool get isLoading => _loading;
  bool get isMutating => _mutating;
  String? get error => _error;
  List<AdminAiPrompt> get prompts => _prompts;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _prompts = await repository.list();
    } catch (error) {
      _error = 'Chargement des prompts impossible. Vérifiez vos droits.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> saveDraft({required String? draftId, required String key, required String content}) =>
      _mutate(() => repository.saveDraft(draftId: draftId, key: key, content: content));

  /// Retourne la réponse obtenue, ou `null` en cas d'échec (le message
  /// d'erreur est déjà posé dans [error]).
  Future<String?> testDraft({
    required String draftId,
    required String draftContent,
    required String testMessage,
  }) async {
    _mutating = true;
    _error = null;
    notifyListeners();
    try {
      final response = await repository.testDraft(
        draftId: draftId,
        draftContent: draftContent,
        testMessage: testMessage,
      );
      await load();
      return response;
    } on PostgrestException catch (error) {
      _error = error.message;
      return null;
    } catch (error) {
      _error = 'Le test n\'a pas pu être enregistré (appel au modèle interrompu ?).';
      return null;
    } finally {
      _mutating = false;
      notifyListeners();
    }
  }

  Future<bool> publish(String draftId) => _mutate(() => repository.publish(draftId));

  Future<bool> _mutate(Future<void> Function() action) async {
    _mutating = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      await load();
      return true;
    } on PostgrestException catch (error) {
      _error = error.message;
      return false;
    } catch (error) {
      _error = 'L\'action n\'a pas pu être enregistrée.';
      return false;
    } finally {
      _mutating = false;
      notifyListeners();
    }
  }

  void dismissError() {
    _error = null;
    notifyListeners();
  }
}
