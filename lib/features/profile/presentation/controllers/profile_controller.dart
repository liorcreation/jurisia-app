import 'package:flutter/foundation.dart';

import '../../../../core/storage/local_cache.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/user_profession.dart';
import '../../domain/repositories/profile_repository.dart';

/// État de la carte profil de la sidebar : charge le profil de l'utilisateur
/// connecté, enregistre les modifications (nom, rôle), et gère la
/// déconnexion.
///
/// Le profil est d'abord servi depuis le cache local (affichage instantané,
/// sans état de chargement visible), puis rafraîchi silencieusement depuis
/// le réseau en arrière-plan.
class ProfileController extends ChangeNotifier {
  ProfileController({
    required this.profileRepository,
    required this.authRepository,
    this.cacheKey,
  }) {
    _profile = _readCache();
    load();
  }

  final ProfileRepository profileRepository;
  final AuthRepository authRepository;

  /// Clé de cache local du profil (typiquement propre à l'utilisateur).
  /// `null` désactive le cache.
  final String? cacheKey;

  UserProfile? _profile;
  UserProfile? get profile => _profile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  Future<void> load() async {
    // On ne montre un état de chargement que si rien n'est déjà affiché :
    // avec un profil en cache, le rafraîchissement reste invisible.
    final hadProfile = _profile != null;
    if (!hadProfile) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      final loaded = await profileRepository.load();
      if (loaded != null) {
        _profile = loaded;
        _writeCache(loaded);
      }
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
        _writeCache(_profile!);
      } else {
        await load();
      }
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    final key = cacheKey;
    if (key != null) await LocalCache.instance?.remove(key);
    await authRepository.signOut();
  }

  UserProfile? _readCache() {
    final key = cacheKey;
    final cache = LocalCache.instance;
    if (key == null || cache == null) return null;
    return cache.readJson<UserProfile>(
      key,
      (decoded) => UserProfile.fromJson(decoded as Map<String, dynamic>),
    );
  }

  void _writeCache(UserProfile profile) {
    final key = cacheKey;
    final cache = LocalCache.instance;
    if (key == null || cache == null) return;
    // ignore: unawaited_futures
    cache.writeJson(key, profile.toJson());
  }
}
