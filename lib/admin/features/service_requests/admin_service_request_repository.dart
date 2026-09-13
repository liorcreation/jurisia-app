import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/contact_professional/domain/entities/professional_category.dart';
import '../../../features/professional/domain/entities/professional_service_request.dart';

abstract class AdminServiceRequestRepository {
  Future<List<ProfessionalServiceRequest>> list();

  Future<ProfessionalServiceRequest> updateStatus({
    required String requestId,
    required ProfessionalServiceRequestStatus status,
    num? quoteAmount,
    String? quoteCurrency,
    String? depositUrl,
    String? dropoffLocation,
    String? pickupLocation,
  });
}

class SupabaseAdminServiceRequestRepository
    implements AdminServiceRequestRepository {
  SupabaseAdminServiceRequestRepository({required this.client});

  final SupabaseClient client;

  @override
  Future<List<ProfessionalServiceRequest>> list() async {
    final rows = await client
        .from('professional_service_requests')
        .select()
        .order('created_at', ascending: false)
        .limit(200);
    return (rows as List)
        .map((row) => _fromRow((row as Map).cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<ProfessionalServiceRequest> updateStatus({
    required String requestId,
    required ProfessionalServiceRequestStatus status,
    num? quoteAmount,
    String? quoteCurrency,
    String? depositUrl,
    String? dropoffLocation,
    String? pickupLocation,
  }) async {
    final response = await client.functions.invoke(
      'professional-request-notify',
      body: {
        'requestId': requestId,
        'status': status.name,
        'quoteAmount': quoteAmount,
        'quoteCurrency': quoteCurrency,
        'depositUrl': depositUrl,
        'dropoffLocation': dropoffLocation,
        'pickupLocation': pickupLocation,
      },
    );
    final payload = response.data;
    if (payload is! Map || payload['request'] is! Map) {
      throw StateError('Réponse de notification invalide.');
    }
    return _fromRow(Map<String, dynamic>.from(payload['request'] as Map));
  }

  ProfessionalServiceRequest _fromRow(Map<String, dynamic> row) {
    DateTime? parseDate(Object? value) =>
        value == null ? null : DateTime.tryParse(value.toString());
    return ProfessionalServiceRequest(
      id: row['id'] as String,
      kind: ProfessionalRequestKind.values.firstWhere(
        (value) => value.name == row['kind'],
        orElse: () => ProfessionalRequestKind.legalAct,
      ),
      category: _categoryFromName(row['category'] as String? ?? 'juriste'),
      actType: row['act_type'] as String?,
      fullName: row['full_name'] as String? ?? '',
      email: row['email'] as String? ?? '',
      phone: row['phone'] as String? ?? '',
      details: row['details'] as String? ?? '',
      urgency: ProfessionalRequestUrgency.values.firstWhere(
        (value) => value.name == row['urgency'],
        orElse: () => ProfessionalRequestUrgency.standard,
      ),
      attachmentNames:
          (row['attachment_names'] as List?)
              ?.map((value) => value.toString())
              .toList(growable: false) ??
          const [],
      desiredDate: parseDate(row['desired_date']),
      appointmentMode: row['appointment_mode'] == null
          ? null
          : ProfessionalAppointmentMode.values.firstWhere(
              (value) => value.name == row['appointment_mode'],
              orElse: () => ProfessionalAppointmentMode.video,
            ),
      createdAt: parseDate(row['created_at']) ?? DateTime.now(),
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

ProfessionalCategory _categoryFromName(String name) =>
    ProfessionalCategory.fromName(name);
