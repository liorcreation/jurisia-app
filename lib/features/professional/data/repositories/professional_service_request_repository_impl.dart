import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../contact_professional/domain/entities/professional_category.dart';
import '../../domain/entities/professional_service_request.dart';
import '../../domain/repositories/professional_service_request_repository.dart';

class ProfessionalServiceRequestRepositoryImpl
    implements ProfessionalServiceRequestRepository {
  ProfessionalServiceRequestRepositoryImpl({
    this.supabaseClient,
    this.userId,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  final SupabaseClient? supabaseClient;
  final String? userId;
  final Uuid _uuid;
  final List<ProfessionalServiceRequest> _requests = [];

  bool get _persistenceEnabled => supabaseClient != null && userId != null;

  @override
  List<ProfessionalServiceRequest> get requests => List.unmodifiable(_requests);

  @override
  Future<void> hydrate() async {
    if (!_persistenceEnabled) return;
    try {
      final rows = await supabaseClient!
          .from('professional_service_requests')
          .select()
          .eq('user_id', userId!)
          .order('created_at', ascending: false)
          .limit(50);
      _requests
        ..clear()
        ..addAll(
          (rows as List).map((row) => _fromRow(row as Map<String, dynamic>)),
        );
    } catch (error) {
      // ignore: avoid_print
      print('Échec du chargement des demandes professionnelles : $error');
    }
  }

  @override
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
  }) async {
    if (!_persistenceEnabled) {
      throw StateError('Vous devez être connecté pour envoyer cette demande.');
    }

    final request = ProfessionalServiceRequest(
      id: _uuid.v4(),
      kind: kind,
      category: ProfessionalCategory.fromName(category),
      actType: actType,
      fullName: fullName,
      email: email,
      phone: phone,
      details: details,
      urgency: urgency,
      attachmentNames: attachmentNames,
      desiredDate: desiredDate,
      appointmentMode: appointmentMode,
      createdAt: DateTime.now(),
    );

    final response = await supabaseClient!.functions.invoke(
      'professional-request',
      body: {
        'id': request.id,
        'kind': kind.name,
        'category': category,
        'actType': actType,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'details': details,
        'urgency': urgency.name,
        'attachmentNames': attachmentNames,
        'desiredDate': desiredDate?.toIso8601String(),
        'appointmentMode': appointmentMode?.name,
      },
    );

    final payload = response.data;
    final returned = payload is Map && payload['request'] is Map
        ? _fromRow(Map<String, dynamic>.from(payload['request'] as Map))
        : request;
    _requests.insert(0, returned);
    return returned;
  }

  ProfessionalServiceRequest _fromRow(Map<String, dynamic> row) {
    DateTime? parseDate(Object? value) =>
        value == null ? null : DateTime.tryParse(value.toString());
    final desiredDate = parseDate(row['desired_date']);
    final createdAt = parseDate(row['created_at']) ?? DateTime.now();
    final attachments = (row['attachment_names'] as List?)
        ?.map((value) => value.toString())
        .toList(growable: false);

    return ProfessionalServiceRequest(
      id: row['id'] as String,
      kind: ProfessionalRequestKind.values.firstWhere(
        (value) => value.name == row['kind'],
        orElse: () => ProfessionalRequestKind.legalAct,
      ),
      category: ProfessionalCategory.fromName(
        row['category'] as String? ?? 'juriste',
      ),
      actType: row['act_type'] as String?,
      fullName: row['full_name'] as String? ?? '',
      email: row['email'] as String? ?? '',
      phone: row['phone'] as String? ?? '',
      details: row['details'] as String? ?? '',
      urgency: ProfessionalRequestUrgency.values.firstWhere(
        (value) => value.name == row['urgency'],
        orElse: () => ProfessionalRequestUrgency.standard,
      ),
      attachmentNames: attachments ?? const [],
      desiredDate: desiredDate,
      appointmentMode: row['appointment_mode'] == null
          ? null
          : ProfessionalAppointmentMode.values.firstWhere(
              (value) => value.name == row['appointment_mode'],
              orElse: () => ProfessionalAppointmentMode.video,
            ),
      createdAt: createdAt,
      status: ProfessionalServiceRequestStatus.values.firstWhere(
        (value) => value.name == row['status'],
        orElse: () => ProfessionalServiceRequestStatus.submitted,
      ),
      quoteAmount: row['quote_amount'] as num?,
      quoteCurrency: row['quote_currency'] as String? ?? 'XOF',
      depositUrl: row['deposit_url'] as String?,
      dropoffLocation: row['dropoff_location'] as String?,
      pickupLocation: row['pickup_location'] as String?,
    );
  }
}
