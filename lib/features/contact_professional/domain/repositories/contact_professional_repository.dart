import '../entities/contact_request.dart';
import '../entities/professional_category.dart';

/// Frontière de persistance du module « Contacter un professionnel ».
abstract class ContactProfessionalRepository {
  /// Les demandes de l'utilisateur courant, les plus récentes en premier.
  List<ContactRequest> get requests;

  /// Charge l'historique des demandes depuis Supabase, sans effet si la
  /// persistance n'est pas configurée (voir les implémentations).
  Future<void> hydrate();

  /// Enregistre une nouvelle demande de mise en relation. Contrairement aux
  /// autres modules (favoris, compteurs) dont la persistance est du
  /// meilleur effort en arrière-plan, cet appel attend réellement
  /// l'écriture Supabase et propage l'échec : une demande de contact que
  /// l'utilisateur croit envoyée alors qu'elle ne l'est pas est un problème
  /// bien plus grave qu'un favori perdu.
  Future<ContactRequest> submitRequest({
    required ProfessionalCategory category,
    required String fullName,
    required String contactInfo,
    required String message,
  });
}
