/// Rôles de personnel de la console d'administration (voir la contrainte
/// CHECK de `staff_roles` dans `migration_006_roles_and_audit.sql`).
enum StaffRole {
  superAdmin,
  admin,
  contentEditor,
  legalReviewer,
  partnerManager,
  supportAgent,
  analyst;

  /// Nom stocké en base (`snake_case`).
  String get wireName {
    switch (this) {
      case StaffRole.superAdmin:
        return 'super_admin';
      case StaffRole.admin:
        return 'admin';
      case StaffRole.contentEditor:
        return 'content_editor';
      case StaffRole.legalReviewer:
        return 'legal_reviewer';
      case StaffRole.partnerManager:
        return 'partner_manager';
      case StaffRole.supportAgent:
        return 'support_agent';
      case StaffRole.analyst:
        return 'analyst';
    }
  }

  String get label {
    switch (this) {
      case StaffRole.superAdmin:
        return 'Super administrateur';
      case StaffRole.admin:
        return 'Administrateur';
      case StaffRole.contentEditor:
        return 'Éditeur juridique';
      case StaffRole.legalReviewer:
        return 'Réviseur juridique';
      case StaffRole.partnerManager:
        return 'Responsable partenaires';
      case StaffRole.supportAgent:
        return 'Agent support';
      case StaffRole.analyst:
        return 'Analyste';
    }
  }

  static StaffRole? fromWireName(String? value) {
    if (value == null) return null;
    for (final role in StaffRole.values) {
      if (role.wireName == value) return role;
    }
    return null;
  }
}

/// L'ensemble des rôles d'un membre du personnel + les autorisations qui en
/// découlent. Un ensemble vide = pas un membre du personnel (accès refusé).
class StaffIdentity {
  const StaffIdentity(this.roles);

  const StaffIdentity.none() : roles = const {};

  final Set<StaffRole> roles;

  bool get isStaff => roles.isNotEmpty;

  bool has(StaffRole role) => roles.contains(role);

  /// Accès aux opérations (utilisateurs, demandes de mise en relation…).
  bool get canOperate =>
      roles.contains(StaffRole.superAdmin) ||
      roles.contains(StaffRole.admin) ||
      roles.contains(StaffRole.supportAgent) ||
      roles.contains(StaffRole.partnerManager);

  /// Accès aux données de facturation.
  bool get canSeeBilling =>
      roles.contains(StaffRole.superAdmin) ||
      roles.contains(StaffRole.admin) ||
      roles.contains(StaffRole.analyst);

  /// Accorder / retirer un rôle de personnel — réservé aux super
  /// administrateurs (voir migration_011_staff_management.sql). Le reste du
  /// personnel peut consulter la liste, jamais la modifier.
  bool get canManageStaff => roles.contains(StaffRole.superAdmin);

  /// Rédiger un brouillon (texte de la bibliothèque ou prompt IA) — voir
  /// migration_012/013, fonction `jurisia_can_edit_content()` côté serveur
  /// (même liste de rôles, gardée manuellement synchronisée ici pour l'UI).
  bool get canEditContent =>
      roles.contains(StaffRole.contentEditor) ||
      roles.contains(StaffRole.legalReviewer) ||
      roles.contains(StaffRole.admin) ||
      roles.contains(StaffRole.superAdmin);

  /// Approuver/rejeter un brouillon de texte, ou l'archiver — CMS
  /// Bibliothèque uniquement (voir migration_012).
  bool get canReviewDocuments =>
      roles.contains(StaffRole.legalReviewer) ||
      roles.contains(StaffRole.admin) ||
      roles.contains(StaffRole.superAdmin);

  /// Publier un prompt — réservé aux super administrateurs (voir
  /// migration_013 : le risque touche tous les utilisateurs d'un coup,
  /// contrairement à un texte de bibliothèque qui reste contenu à lui-même).
  bool get canPublishPrompts => roles.contains(StaffRole.superAdmin);

  /// Le plus haut rôle, pour l'affichage.
  StaffRole? get primary {
    for (final role in StaffRole.values) {
      if (roles.contains(role)) return role;
    }
    return null;
  }
}
