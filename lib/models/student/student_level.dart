/// Niveau universitaire sélectionné par l'étudiant à sa première connexion.
enum AcademicLevel { l1, l2, l3, m1, m2 }

extension AcademicLevelLabel on AcademicLevel {
  String get shortLabel {
    switch (this) {
      case AcademicLevel.l1:
        return 'L1';
      case AcademicLevel.l2:
        return 'L2';
      case AcademicLevel.l3:
        return 'L3';
      case AcademicLevel.m1:
        return 'M1';
      case AcademicLevel.m2:
        return 'M2';
    }
  }

  String get fullLabel {
    switch (this) {
      case AcademicLevel.l1:
        return 'Licence 1 — Introduction au droit';
      case AcademicLevel.l2:
        return 'Licence 2';
      case AcademicLevel.l3:
        return 'Licence 3';
      case AcademicLevel.m1:
        return 'Master 1';
      case AcademicLevel.m2:
        return 'Master 2';
    }
  }

  static AcademicLevel fromName(String name) {
    return AcademicLevel.values.firstWhere(
      (level) => level.name == name,
      orElse: () => AcademicLevel.l1,
    );
  }
}
