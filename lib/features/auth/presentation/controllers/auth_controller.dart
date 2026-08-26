import 'package:flutter/foundation.dart';

import '../../domain/repositories/auth_repository.dart';

enum AuthMode { signIn, signUp }

enum AuthStatus { idle, submitting, error }

/// Contrôleur d'état de l'écran de connexion/inscription : conserve le mode
/// courant et relaie les mutations au [AuthRepository].
class AuthController extends ChangeNotifier {
  AuthController({required this.repository});

  final AuthRepository repository;

  AuthMode _mode = AuthMode.signIn;
  AuthMode get mode => _mode;

  AuthStatus _status = AuthStatus.idle;
  AuthStatus get status => _status;
  bool get isSubmitting => _status == AuthStatus.submitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _termsAccepted = false;
  bool get termsAccepted => _termsAccepted;

  void toggleMode() {
    _mode = _mode == AuthMode.signIn ? AuthMode.signUp : AuthMode.signIn;
    _errorMessage = null;
    notifyListeners();
  }

  void setTermsAccepted(bool value) {
    _termsAccepted = value;
    notifyListeners();
  }

  Future<void> submit({required String email, required String password}) async {
    if (isSubmitting) return;

    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      _status = AuthStatus.error;
      _errorMessage = 'Renseignez votre e-mail et votre mot de passe.';
      notifyListeners();
      return;
    }
    if (password.length < 6) {
      _status = AuthStatus.error;
      _errorMessage = 'Le mot de passe doit contenir au moins 6 caractères.';
      notifyListeners();
      return;
    }
    if (_mode == AuthMode.signUp && !_termsAccepted) {
      _status = AuthStatus.error;
      _errorMessage = "Vous devez accepter les CGU et la politique de confidentialité pour créer un compte.";
      notifyListeners();
      return;
    }

    _status = AuthStatus.submitting;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_mode == AuthMode.signIn) {
        await repository.signIn(email: trimmedEmail, password: password);
      } else {
        await repository.signUp(email: trimmedEmail, password: password);
        await repository.recordTermsAcceptance();
      }
      _status = AuthStatus.idle;
      notifyListeners();
    } catch (error) {
      _status = AuthStatus.error;
      _errorMessage = _friendlyMessage(error);
      notifyListeners();
    }
  }

  String _friendlyMessage(Object error) {
    final raw = error.toString();
    if (raw.contains('Invalid login credentials')) {
      return 'E-mail ou mot de passe incorrect.';
    }
    if (raw.contains('User already registered')) {
      return 'Un compte existe déjà avec cet e-mail — connectez-vous plutôt.';
    }
    return raw;
  }
}
