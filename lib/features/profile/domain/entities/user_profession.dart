/// Réponse au « Vous êtes ? » de l'inscription — affichée sous le nom dans
/// la carte profil de la sidebar, modifiable ensuite depuis la feuille
/// profil. Stockée en base sous forme de [name] (`profiles.profession`).
enum UserProfession {
  particulier,
  etudiantDroit,
  avocat,
  notaire,
  huissier,
  juriste,
  autre;

  String get label {
    switch (this) {
      case UserProfession.particulier:
        return 'Particulier';
      case UserProfession.etudiantDroit:
        return 'Étudiant en droit';
      case UserProfession.avocat:
        return 'Avocat';
      case UserProfession.notaire:
        return 'Notaire';
      case UserProfession.huissier:
        return 'Huissier de justice';
      case UserProfession.juriste:
        return 'Juriste';
      case UserProfession.autre:
        return 'Autre';
    }
  }

  static UserProfession? fromName(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final profession in UserProfession.values) {
      if (profession.name == value) return profession;
    }
    return null;
  }
}
