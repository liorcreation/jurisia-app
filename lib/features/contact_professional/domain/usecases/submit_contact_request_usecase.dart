import '../entities/contact_request.dart';
import '../entities/professional_category.dart';
import '../repositories/contact_professional_repository.dart';

/// Valide puis soumet une demande de mise en relation avec un
/// professionnel du droit.
class SubmitContactRequestUseCase {
  const SubmitContactRequestUseCase({required this.repository});

  final ContactProfessionalRepository repository;

  Future<ContactRequest> call({
    required ProfessionalCategory category,
    required String fullName,
    required String contactInfo,
    required String message,
  }) {
    final trimmedName = fullName.trim();
    final trimmedContact = contactInfo.trim();
    final trimmedMessage = message.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError('Merci d\'indiquer votre nom complet.');
    }
    if (trimmedContact.isEmpty) {
      throw ArgumentError('Merci d\'indiquer un téléphone ou un e-mail pour être recontacté.');
    }
    if (trimmedMessage.isEmpty) {
      throw ArgumentError('Merci de décrire brièvement votre besoin.');
    }

    return repository.submitRequest(
      category: category,
      fullName: trimmedName,
      contactInfo: trimmedContact,
      message: trimmedMessage,
    );
  }
}
