import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/contact_request.dart';
import '../../domain/entities/professional_category.dart';
import '../../domain/repositories/contact_professional_repository.dart';

/// Implémentation Supabase du [ContactProfessionalRepository]. Sans
/// [supabaseClient]/[userId] (utilisateur non connecté, ou tests), les
/// demandes restent en mémoire pour la session mais [submitRequest] échoue
/// explicitement : contrairement aux favoris ou aux compteurs des autres
/// modules, une demande de mise en relation qui ne serait jamais vue par
/// personne n'a aucune valeur, donc pas de mode « local silencieux » ici.
class ContactProfessionalRepositoryImpl implements ContactProfessionalRepository {
  ContactProfessionalRepositoryImpl({this.supabaseClient, this.userId, Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  final SupabaseClient? supabaseClient;
  final String? userId;
  final Uuid _uuid;

  final List<ContactRequest> _requests = [];

  bool get _persistenceEnabled => supabaseClient != null && userId != null;

  @override
  List<ContactRequest> get requests => List.unmodifiable(_requests);

  @override
  Future<void> hydrate() async {
    if (!_persistenceEnabled) return;

    try {
      final rows = await supabaseClient!
          .from('professional_contact_requests')
          .select()
          .eq('user_id', userId!)
          .order('created_at', ascending: false)
          .limit(50);

      _requests
        ..clear()
        ..addAll((rows as List).map((row) => _fromRow(row as Map<String, dynamic>)));
    } catch (error) {
      // ignore: avoid_print
      print('Échec du chargement des demandes de contact Supabase : $error');
    }
  }

  @override
  Future<ContactRequest> submitRequest({
    required ProfessionalCategory category,
    required String fullName,
    required String contactInfo,
    required String message,
  }) async {
    if (!_persistenceEnabled) {
      throw StateError('Vous devez être connecté pour envoyer une demande de contact.');
    }

    final request = ContactRequest(
      id: _uuid.v4(),
      category: category,
      fullName: fullName,
      contactInfo: contactInfo,
      message: message,
      createdAt: DateTime.now(),
    );

    await supabaseClient!.from('professional_contact_requests').insert({
      'id': request.id,
      'user_id': userId,
      'category': request.category.name,
      'full_name': request.fullName,
      'contact_info': request.contactInfo,
      'message': request.message,
      'status': request.status.name,
    });

    _requests.insert(0, request);
    return request;
  }

  ContactRequest _fromRow(Map<String, dynamic> row) {
    return ContactRequest(
      id: row['id'] as String,
      category: ProfessionalCategory.fromName(row['category'] as String),
      fullName: row['full_name'] as String,
      contactInfo: row['contact_info'] as String,
      message: row['message'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      status: ContactRequestStatus.fromName(row['status'] as String),
    );
  }
}
