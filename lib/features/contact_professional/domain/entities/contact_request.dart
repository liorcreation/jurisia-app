import 'professional_category.dart';

/// Où en est la prise en charge d'une demande de mise en relation par
/// l'équipe JurisIA / ses partenaires.
enum ContactRequestStatus {
  pending,
  contacted,
  closed;

  static ContactRequestStatus fromName(String name) {
    return ContactRequestStatus.values.firstWhere(
      (value) => value.name == name,
      orElse: () => ContactRequestStatus.pending,
    );
  }
}

extension ContactRequestStatusLabel on ContactRequestStatus {
  String get label {
    switch (this) {
      case ContactRequestStatus.pending:
        return 'En attente';
      case ContactRequestStatus.contacted:
        return 'Prise en charge';
      case ContactRequestStatus.closed:
        return 'Clôturée';
    }
  }
}

/// Une demande de mise en relation avec un professionnel du droit,
/// soumise par l'utilisateur depuis le module « Contacter un professionnel ».
class ContactRequest {
  const ContactRequest({
    required this.id,
    required this.category,
    required this.fullName,
    required this.contactInfo,
    required this.message,
    required this.createdAt,
    this.status = ContactRequestStatus.pending,
  });

  final String id;
  final ProfessionalCategory category;
  final String fullName;

  /// Téléphone ou e-mail au choix de l'utilisateur — le moyen par lequel le
  /// professionnel partenaire le recontactera.
  final String contactInfo;
  final String message;
  final DateTime createdAt;
  final ContactRequestStatus status;
}
