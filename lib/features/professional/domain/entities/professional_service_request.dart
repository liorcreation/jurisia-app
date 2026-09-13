import '../../../contact_professional/domain/entities/professional_category.dart';

enum ProfessionalRequestKind { legalAct, expertAppointment }

extension ProfessionalRequestKindDetails on ProfessionalRequestKind {
  String get label => switch (this) {
    ProfessionalRequestKind.legalAct => 'Demande d’acte juridique',
    ProfessionalRequestKind.expertAppointment => 'Rendez-vous avec un expert',
  };

  String get description => switch (this) {
    ProfessionalRequestKind.legalAct =>
      'Confiez la préparation d’un acte, d’un contrat ou d’un dossier.',
    ProfessionalRequestKind.expertAppointment =>
      'Planifiez un échange avec le professionnel le plus adapté.',
  };
}

enum ProfessionalRequestUrgency { standard, priority, urgent }

extension ProfessionalRequestUrgencyDetails on ProfessionalRequestUrgency {
  String get label => switch (this) {
    ProfessionalRequestUrgency.standard => 'Standard — 3 à 5 jours',
    ProfessionalRequestUrgency.priority => 'Prioritaire — 24 à 48 h',
    ProfessionalRequestUrgency.urgent => 'Urgent — prise en charge immédiate',
  };
}

enum ProfessionalAppointmentMode { phone, video, inPerson }

extension ProfessionalAppointmentModeDetails on ProfessionalAppointmentMode {
  String get label => switch (this) {
    ProfessionalAppointmentMode.phone => 'Téléphone',
    ProfessionalAppointmentMode.video => 'Visioconférence',
    ProfessionalAppointmentMode.inPerson => 'En cabinet',
  };
}

enum ProfessionalServiceRequestStatus {
  submitted,
  acknowledged,
  quoteReady,
  scheduled,
  closed,
  cancelled,
}

extension ProfessionalServiceRequestStatusDetails
    on ProfessionalServiceRequestStatus {
  String get label => switch (this) {
    ProfessionalServiceRequestStatus.submitted => 'Reçue',
    ProfessionalServiceRequestStatus.acknowledged => 'Prise en charge',
    ProfessionalServiceRequestStatus.quoteReady => 'Devis disponible',
    ProfessionalServiceRequestStatus.scheduled => 'Rendez-vous confirmé',
    ProfessionalServiceRequestStatus.closed => 'Terminée',
    ProfessionalServiceRequestStatus.cancelled => 'Annulée',
  };
}

/// Demande commerciale structurée, distincte d’un simple message de contact.
/// Elle porte le contexte nécessaire au devis, à la prise de rendez-vous et
/// aux notifications transactionnelles Supabase.
class ProfessionalServiceRequest {
  const ProfessionalServiceRequest({
    required this.id,
    required this.kind,
    required this.category,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.details,
    required this.urgency,
    required this.createdAt,
    this.actType,
    this.attachmentNames = const [],
    this.desiredDate,
    this.appointmentMode,
    this.status = ProfessionalServiceRequestStatus.submitted,
    this.quoteAmount,
    this.quoteCurrency = 'XOF',
    this.depositUrl,
    this.dropoffLocation,
    this.pickupLocation,
  });

  final String id;
  final ProfessionalRequestKind kind;
  final ProfessionalCategory category;
  final String? actType;
  final String fullName;
  final String email;
  final String phone;
  final String details;
  final ProfessionalRequestUrgency urgency;
  final List<String> attachmentNames;
  final DateTime? desiredDate;
  final ProfessionalAppointmentMode? appointmentMode;
  final DateTime createdAt;
  final ProfessionalServiceRequestStatus status;
  final num? quoteAmount;
  final String quoteCurrency;
  final String? depositUrl;
  final String? dropoffLocation;
  final String? pickupLocation;

  ProfessionalServiceRequest copyWith({
    ProfessionalServiceRequestStatus? status,
    num? quoteAmount,
    String? quoteCurrency,
    String? depositUrl,
    String? dropoffLocation,
    String? pickupLocation,
  }) {
    return ProfessionalServiceRequest(
      id: id,
      kind: kind,
      category: category,
      actType: actType,
      fullName: fullName,
      email: email,
      phone: phone,
      details: details,
      urgency: urgency,
      attachmentNames: attachmentNames,
      desiredDate: desiredDate,
      appointmentMode: appointmentMode,
      createdAt: createdAt,
      status: status ?? this.status,
      quoteAmount: quoteAmount ?? this.quoteAmount,
      quoteCurrency: quoteCurrency ?? this.quoteCurrency,
      depositUrl: depositUrl ?? this.depositUrl,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      pickupLocation: pickupLocation ?? this.pickupLocation,
    );
  }
}
