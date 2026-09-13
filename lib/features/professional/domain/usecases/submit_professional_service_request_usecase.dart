import '../entities/professional_service_request.dart';
import '../repositories/professional_service_request_repository.dart';

class SubmitProfessionalServiceRequestUseCase {
  const SubmitProfessionalServiceRequestUseCase({required this.repository});

  final ProfessionalServiceRequestRepository repository;

  Future<ProfessionalServiceRequest> call({
    required ProfessionalRequestKind kind,
    required String category,
    required String? actType,
    required String fullName,
    required String email,
    required String phone,
    required String details,
    required ProfessionalRequestUrgency urgency,
    required List<String> attachmentNames,
    required DateTime? desiredDate,
    required ProfessionalAppointmentMode? appointmentMode,
  }) {
    final normalizedName = fullName.trim();
    final normalizedEmail = email.trim();
    final normalizedPhone = phone.trim();
    final normalizedDetails = details.trim();
    final normalizedActType = actType?.trim();

    if (normalizedName.length < 2) {
      throw ArgumentError('Indiquez votre nom complet.');
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalizedEmail)) {
      throw ArgumentError('Indiquez une adresse e-mail valide.');
    }
    if (normalizedPhone.length < 6) {
      throw ArgumentError('Indiquez un numéro de téléphone joignable.');
    }
    if (normalizedDetails.length < 12) {
      throw ArgumentError('Décrivez votre besoin en quelques phrases.');
    }
    if (kind == ProfessionalRequestKind.legalAct &&
        (normalizedActType == null || normalizedActType.isEmpty)) {
      throw ArgumentError('Précisez le type d’acte souhaité.');
    }
    if (kind == ProfessionalRequestKind.expertAppointment &&
        desiredDate == null) {
      throw ArgumentError('Choisissez une date souhaitée pour le rendez-vous.');
    }

    return repository.submitRequest(
      kind: kind,
      category: category,
      actType: normalizedActType?.isEmpty == true ? null : normalizedActType,
      fullName: normalizedName,
      email: normalizedEmail,
      phone: normalizedPhone,
      details: normalizedDetails,
      urgency: urgency,
      attachmentNames: attachmentNames
          .map((name) => name.trim())
          .where((name) => name.isNotEmpty)
          .toList(growable: false),
      desiredDate: desiredDate,
      appointmentMode: appointmentMode,
    );
  }
}
