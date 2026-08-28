import '../../../features/contact_professional/domain/entities/contact_request.dart';
import '../../../features/contact_professional/domain/entities/professional_category.dart';

/// Une demande de mise en relation vue côté console : les mêmes champs que
/// l'utilisateur la voit, plus l'identifiant du compte à l'origine.
class AdminContactRequest {
  const AdminContactRequest({
    required this.id,
    required this.userId,
    required this.category,
    required this.fullName,
    required this.contactInfo,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final ProfessionalCategory category;
  final String fullName;
  final String contactInfo;
  final String message;
  final ContactRequestStatus status;
  final DateTime createdAt;

  AdminContactRequest copyWith({ContactRequestStatus? status}) {
    return AdminContactRequest(
      id: id,
      userId: userId,
      category: category,
      fullName: fullName,
      contactInfo: contactInfo,
      message: message,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  factory AdminContactRequest.fromRow(Map<String, dynamic> row) {
    return AdminContactRequest(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      category: ProfessionalCategory.fromName(row['category'] as String),
      fullName: row['full_name'] as String,
      contactInfo: row['contact_info'] as String,
      message: row['message'] as String,
      status: ContactRequestStatus.fromName(row['status'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
