import '../entities/professional_service_request.dart';

abstract class ProfessionalServiceRequestRepository {
  List<ProfessionalServiceRequest> get requests;

  Future<void> hydrate();

  Future<ProfessionalServiceRequest> submitRequest({
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
  });
}
