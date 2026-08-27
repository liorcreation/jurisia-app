import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/entities/user_profession.dart';
import '../../domain/repositories/profile_repository.dart';

/// Implémentation de [ProfileRepository] adossée à la table `profiles` de
/// Supabase. Lectures/écritures au mieux effort : un échec réseau renvoie un
/// profil minimal (id + e-mail) plutôt qu'une erreur — la carte profil doit
/// toujours pouvoir s'afficher.
class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository({required this.client});

  final SupabaseClient client;

  @override
  Future<UserProfile?> load() async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    final email = user.email ?? '';

    try {
      final rows = await client
          .from('profiles')
          .select('full_name, profession')
          .eq('id', user.id)
          .limit(1);

      if (rows.isEmpty) {
        return UserProfile(id: user.id, email: email);
      }
      final row = rows.first;
      return UserProfile(
        id: user.id,
        email: email,
        fullName: row['full_name'] as String?,
        profession: UserProfession.fromName(row['profession'] as String?),
      );
    } catch (error) {
      // ignore: avoid_print
      print('Échec du chargement du profil : $error');
      return UserProfile(id: user.id, email: email);
    }
  }

  @override
  Future<void> save({String? fullName, UserProfession? profession}) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    final payload = <String, dynamic>{'id': user.id};
    if (fullName != null) payload['full_name'] = fullName.trim();
    if (profession != null) payload['profession'] = profession.name;

    try {
      await client.from('profiles').upsert(payload);
    } catch (error) {
      // ignore: avoid_print
      print('Échec de l\'enregistrement du profil : $error');
    }
  }
}
