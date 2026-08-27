import '../../../core/supabase/supabase_config.dart';
import '../../auth/data/repositories/supabase_auth_repository.dart';
import '../../auth/domain/entities/auth_user.dart';
import '../../auth/domain/repositories/auth_repository.dart';
import '../data/repositories/supabase_profile_repository.dart';
import '../domain/entities/user_profile.dart';
import '../domain/entities/user_profession.dart';
import '../domain/repositories/profile_repository.dart';
import 'controllers/profile_controller.dart';

/// Assemble le [ProfileController] fourni par la coquille applicative
/// ([AppShell]). Dégrade proprement quand Supabase n'est pas configuré : la
/// carte profil affiche alors un profil vide plutôt que de planter.
ProfileController buildProfileController() {
  if (!SupabaseConfig.isReady) {
    return ProfileController(
      profileRepository: const _EmptyProfileRepository(),
      authRepository: const _NoopAuthRepository(),
    );
  }
  return ProfileController(
    profileRepository: SupabaseProfileRepository(client: SupabaseConfig.client),
    authRepository: SupabaseAuthRepository(client: SupabaseConfig.client),
  );
}

class _EmptyProfileRepository implements ProfileRepository {
  const _EmptyProfileRepository();

  @override
  Future<UserProfile?> load() async => null;

  @override
  Future<void> save({String? fullName, UserProfession? profession}) async {}
}

class _NoopAuthRepository implements AuthRepository {
  const _NoopAuthRepository();

  @override
  Stream<AuthUser?> get authStateChanges => const Stream.empty();

  @override
  AuthUser? get currentUser => null;

  @override
  Future<void> signUp({
    required String email,
    required String password,
    String? fullName,
    String? profession,
  }) async {}

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> recordTermsAcceptance() async {}
}
