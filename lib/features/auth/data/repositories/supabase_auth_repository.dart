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
  Future<void> signUp({required String email, required String password}) async {
    await _client.auth.signUp(email: email, password: password);
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
