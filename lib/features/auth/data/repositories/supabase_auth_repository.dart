import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase show User;

import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implémentation de [AuthRepository] adossée à l'authentification par
/// e-mail/mot de passe de Supabase.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({required this._client});

  final SupabaseClient _client;

  AuthUser? _toAuthUser(supabase.User? user) {
    if (user == null || user.email == null) return null;
    return AuthUser(id: user.id, email: user.email!);
  }

  @override
  Stream<AuthUser?> get authStateChanges =>
      _client.auth.onAuthStateChange.map((state) => _toAuthUser(state.session?.user));

  @override
  AuthUser? get currentUser => _toAuthUser(_client.auth.currentUser);

  @override
  Future<void> signUp({
    required String email,
    required String password,
    String? fullName,
    String? profession,
  }) async {
    final metadata = <String, dynamic>{};
    if (fullName != null && fullName.trim().isNotEmpty) metadata['full_name'] = fullName.trim();
    if (profession != null && profession.isNotEmpty) metadata['profession'] = profession;

    await _client.auth.signUp(
      email: email,
      password: password,
      data: metadata.isEmpty ? null : metadata,
    );

    // Repli : si le déclencheur `on_auth_user_created` n'a pas encore été
    // redéployé avec la copie des métadonnées, on écrit quand même la ligne
    // de profil côté application (au mieux effort).
    if (metadata.isNotEmpty) {
      final id = _client.auth.currentUser?.id;
      if (id != null) {
        try {
          await _client.from('profiles').upsert({'id': id, ...metadata});
        } catch (_) {
          // La confirmation par e-mail peut retarder la session : sans
          // utilisateur courant, le déclencheur reste la source de vérité.
        }
      }
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<void> recordTermsAcceptance() async {
    final id = _client.auth.currentUser?.id;
    if (id == null) return;
    await _client.from('profiles').update({
      'terms_accepted_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }
}
