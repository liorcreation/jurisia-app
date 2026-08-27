import '../entities/user_profile.dart';
import '../entities/user_profession.dart';

/// Frontière data vers le profil utilisateur (`profiles` sur Supabase).
abstract class ProfileRepository {
  /// Charge le profil de l'utilisateur connecté, `null` si personne n'est
  /// authentifié ou si la persistance n'est pas configurée.
  Future<UserProfile?> load();

  /// Met à jour le nom complet et/ou le profil. Sans effet si aucun
  /// utilisateur n'est connecté.
  Future<void> save({String? fullName, UserProfession? profession});
}
