import 'package:equatable/equatable.dart';

import 'user_profession.dart';

/// Profil de l'utilisateur connecté, tel qu'affiché dans la carte profil de
/// la sidebar : identité (nom, rôle) + e-mail du compte.
class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.profession,
  });

  final String id;
  final String email;
  final String? fullName;
  final UserProfession? profession;

  /// Nom à afficher, avec un repli propre sur la partie locale de l'e-mail
  /// quand aucun nom complet n'a été renseigné.
  String get displayName {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final local = email.split('@').first;
    return local.isEmpty ? 'Mon compte' : local;
  }

  /// Deux lettres maximum pour le monogramme.
  String get initials {
    final source = (fullName?.trim().isNotEmpty ?? false) ? fullName!.trim() : email;
    final parts = source.split(RegExp(r'[\s._-]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final word = parts.first;
      return (word.length <= 2 ? word : word.substring(0, 2)).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  String get roleLabel => profession?.label ?? 'Compte JurisIA';

  UserProfile copyWith({String? fullName, UserProfession? profession}) {
    return UserProfile(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      profession: profession ?? this.profession,
    );
  }

  @override
  List<Object?> get props => [id, email, fullName, profession];
}
