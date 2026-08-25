import 'package:equatable/equatable.dart';

/// Utilisateur authentifié, réduit aux informations dont l'application a
/// besoin — le reste du profil Supabase reste une préoccupation de la
/// couche data.
class AuthUser extends Equatable {
  const AuthUser({required this.id, required this.email});

  final String id;
  final String email;

  @override
  List<Object?> get props => [id, email];
}
