import 'package:flutter/foundation.dart';

import '../../domain/entities/contact_request.dart';
import '../../domain/entities/professional_category.dart';
import '../../domain/repositories/contact_professional_repository.dart';
import '../../domain/usecases/submit_contact_request_usecase.dart';

enum ContactSubmissionStatus { idle, submitting, success, error }

/// État de l'écran « Contacter un professionnel » : historique des
/// demandes de l'utilisateur, et progression de l'envoi en cours.
class ContactProfessionalController extends ChangeNotifier {
  ContactProfessionalController({required this.repository, required this.submitUseCase}) {
    repository.hydrate().then((_) => notifyListeners());
  }

  final ContactProfessionalRepository repository;
  final SubmitContactRequestUseCase submitUseCase;

  ContactSubmissionStatus _status = ContactSubmissionStatus.idle;
  String? _errorMessage;

  List<ContactRequest> get requests => repository.requests;
  ContactSubmissionStatus get status => _status;
  String? get errorMessage => _errorMessage;

  Future<bool> submit({
    required ProfessionalCategory category,
    required String fullName,
    required String contactInfo,
    required String message,
  }) async {
    _status = ContactSubmissionStatus.submitting;
    _errorMessage = null;
    notifyListeners();

    try {
      await submitUseCase(
        category: category,
        fullName: fullName,
        contactInfo: contactInfo,
        message: message,
      );
      _status = ContactSubmissionStatus.success;
      notifyListeners();
      return true;
    } on ArgumentError catch (error) {
      _status = ContactSubmissionStatus.error;
      _errorMessage = error.message.toString();
      notifyListeners();
      return false;
    } catch (error) {
      _status = ContactSubmissionStatus.error;
      _errorMessage = "L'envoi a échoué. Vérifiez votre connexion et réessayez.";
      notifyListeners();
      return false;
    }
  }

  void resetStatus() {
    _status = ContactSubmissionStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }
}
