import 'package:flutter_test/flutter_test.dart';
import 'package:jurisia_app/core/storage/local_cache.dart';
import 'package:jurisia_app/features/auth/domain/entities/auth_user.dart';
import 'package:jurisia_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:jurisia_app/features/profile/domain/entities/user_profession.dart';
import 'package:jurisia_app/features/profile/domain/entities/user_profile.dart';
import 'package:jurisia_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:jurisia_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(this._profile);

  UserProfile? _profile;
  int loadCalls = 0;
  Duration loadDelay = Duration.zero;

  @override
  Future<UserProfile?> load() async {
    loadCalls++;
    if (loadDelay > Duration.zero) await Future<void>.delayed(loadDelay);
    return _profile;
  }

  @override
  Future<void> save({String? fullName, UserProfession? profession}) async {
    final current = _profile;
    if (current != null) {
      _profile = current.copyWith(fullName: fullName, profession: profession);
    }
  }
}

class _FakeAuthRepository implements AuthRepository {
  int signOutCalls = 0;

  @override
  Stream<AuthUser?> get authStateChanges => const Stream.empty();

  @override
  AuthUser? get currentUser => null;

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<void> signUp({
    required String email,
    required String password,
    String? fullName,
    String? profession,
  }) async {}

  @override
  Future<void> signOut() async => signOutCalls++;

  @override
  Future<void> recordTermsAcceptance() async {}
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  const cacheKey = 'profile.test';
  const networkProfile = UserProfile(
    id: 'u1',
    email: 'awa@example.com',
    fullName: 'Awa Traoré',
    profession: UserProfession.avocat,
  );

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    LocalCache.debugOverrideInstance(null);
    await LocalCache.initialize();
  });

  tearDown(() => LocalCache.debugOverrideInstance(null));

  test('sans cache, montre un état de chargement puis le profil réseau', () async {
    final repo = _FakeProfileRepository(networkProfile)..loadDelay = const Duration(milliseconds: 20);
    final controller = ProfileController(
      profileRepository: repo,
      authRepository: _FakeAuthRepository(),
      cacheKey: cacheKey,
    );

    expect(controller.isLoading, isTrue);
    expect(controller.profile, isNull);

    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(controller.isLoading, isFalse);
    expect(controller.profile, networkProfile);
  });

  test('avec un profil en cache, affichage instantané et aucun état de chargement', () async {
    // 1er contrôleur : peuple le cache depuis le réseau.
    final seedRepo = _FakeProfileRepository(networkProfile);
    ProfileController(
      profileRepository: seedRepo,
      authRepository: _FakeAuthRepository(),
      cacheKey: cacheKey,
    );
    await _settle();

    // 2e contrôleur : le profil est là dès la construction, sans « loading ».
    final repo = _FakeProfileRepository(networkProfile)..loadDelay = const Duration(milliseconds: 50);
    final controller = ProfileController(
      profileRepository: repo,
      authRepository: _FakeAuthRepository(),
      cacheKey: cacheKey,
    );

    expect(controller.profile, networkProfile);
    expect(controller.isLoading, isFalse);
  });

  test('signOut efface le profil mis en cache', () async {
    final seedRepo = _FakeProfileRepository(networkProfile);
    final auth = _FakeAuthRepository();
    final controller = ProfileController(
      profileRepository: seedRepo,
      authRepository: auth,
      cacheKey: cacheKey,
    );
    await _settle();
    expect(LocalCache.instance!.readJson<Object?>(cacheKey, (d) => d), isNotNull);

    await controller.signOut();

    expect(auth.signOutCalls, 1);
    expect(LocalCache.instance!.readJson<Object?>(cacheKey, (d) => d), isNull);
  });
}
