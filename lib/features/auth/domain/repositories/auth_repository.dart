import '../entities/auth_user.dart';

/// Frontière data vers le fournisseur d'authentification. Permet de
/// substituer, plus tard, un autre fournisseur à Supabase sans toucher au
/// reste de l'architecture.
abstract class AuthRepository {
  /// Émet l'utilisateur courant à chaque changement de session (connexion,
  /// déconnexion, restauration de session persistée), `null` si personne
  /// n'est authentifié.
  Stream<AuthUser?> get authStateChanges;

  AuthUser? get currentUser;

  Future<void> signUp({required String email, required String password});
  Future<void> signIn({required String email, required String password});
  Future<void> signOut();
}
