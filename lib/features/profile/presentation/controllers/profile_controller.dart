import 'package:flutter/foundation.dart';

import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/user_profession.dart';
import '../../domain/repositories/profile_repository.dart';

/// État de la carte profil de la sidebar : charge le profil de l'utilisateur
/// connecté, enregistre les modifications (nom, rôle), et gère la
/// déconnexion.
class ProfileController extends ChangeNotifier {
  ProfileController({required this.profileRepository, required this.authRepository}) {
    load();
  }

  final ProfileRepository profileRepository;
  final AuthRepository authRepository;

  UserProfile? _profile;
  UserProfile? get profile => _profile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _profile = await profileRepository.load();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> save({String? fullName, UserProfession? profession}) async {
    if (_isSaving) return;
    _isSaving = true;
    notifyListeners();
    try {
      await profileRepository.save(fullName: fullName, profession: profession);
      final current = _profile;
      if (current != null) {
        _profile = current.copyWith(fullName: fullName, profession: profession);
      } else {
        await load();
      }
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> signOut() => authRepository.signOut();
}
