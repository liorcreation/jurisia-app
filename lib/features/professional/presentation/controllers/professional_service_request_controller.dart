import 'package:flutter/foundation.dart';

import '../../domain/entities/professional_service_request.dart';
import '../../domain/repositories/professional_service_request_repository.dart';
import '../../domain/usecases/submit_professional_service_request_usecase.dart';

enum ProfessionalRequestSubmissionStatus { idle, submitting, success, error }

class ProfessionalServiceRequestController extends ChangeNotifier {
  ProfessionalServiceRequestController({
    required this.repository,
    required this.submitUseCase,
  }) {
    repository.hydrate().then((_) => notifyListeners());
  }

  final ProfessionalServiceRequestRepository repository;
  final SubmitProfessionalServiceRequestUseCase submitUseCase;

  ProfessionalRequestSubmissionStatus _status =
      ProfessionalRequestSubmissionStatus.idle;
  String? _errorMessage;

  List<ProfessionalServiceRequest> get requests => repository.requests;
  ProfessionalRequestSubmissionStatus get status => _status;
  String? get errorMessage => _errorMessage;

  Future<bool> submit({
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
  }) async {
    _status = ProfessionalRequestSubmissionStatus.submitting;
    _errorMessage = null;
    notifyListeners();

    try {
      await submitUseCase(
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
      );
      _status = ProfessionalRequestSubmissionStatus.success;
      notifyListeners();
      return true;
    } on ArgumentError catch (error) {
      _status = ProfessionalRequestSubmissionStatus.error;
      _errorMessage = error.message.toString();
      notifyListeners();
      return false;
    } on StateError catch (error) {
      _status = ProfessionalRequestSubmissionStatus.error;
      _errorMessage = error.message.toString();
      notifyListeners();
      return false;
    } catch (_) {
      _status = ProfessionalRequestSubmissionStatus.error;
      _errorMessage =
          'La demande n’a pas pu être envoyée. Réessayez dans un instant.';
      notifyListeners();
      return false;
    }
  }

  void resetStatus() {
    _status = ProfessionalRequestSubmissionStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }
}
