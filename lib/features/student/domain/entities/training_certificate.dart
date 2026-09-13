enum TrainingCertificateStatus { pending, issued, revoked }

extension TrainingCertificateStatusDetails on TrainingCertificateStatus {
  String get databaseValue => name;
}

/// Certificat de formation signé électroniquement par JurisIA.
class TrainingCertificate {
  const TrainingCertificate({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.certificateNumber,
    required this.verificationCode,
    required this.status,
    this.issuedAt,
    this.signedAt,
    this.signerName,
    this.signatureHash,
    this.pdfStoragePath,
  });

  final String id;
  final String categoryId;
  final String title;
  final String certificateNumber;
  final String verificationCode;
  final TrainingCertificateStatus status;
  final DateTime? issuedAt;
  final DateTime? signedAt;
  final String? signerName;
  final String? signatureHash;
  final String? pdfStoragePath;

  factory TrainingCertificate.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status']?.toString();
    DateTime? parseDate(Object? value) =>
        value == null ? null : DateTime.tryParse(value.toString());

    return TrainingCertificate(
      id: json['id']?.toString() ?? '',
      categoryId: (json['category_id'] ?? json['categoryId'])?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      certificateNumber:
          (json['certificate_number'] ?? json['certificateNumber'])
              ?.toString() ??
          '',
      verificationCode:
          (json['verification_code'] ?? json['verificationCode'])?.toString() ??
          '',
      status: TrainingCertificateStatus.values.firstWhere(
        (value) => value.name == rawStatus,
        orElse: () => TrainingCertificateStatus.pending,
      ),
      issuedAt: parseDate(json['issued_at'] ?? json['issuedAt']),
      signedAt: parseDate(json['signed_at'] ?? json['signedAt']),
      signerName: (json['signer_name'] ?? json['signerName'])?.toString(),
      signatureHash: (json['signature_hash'] ?? json['signatureHash'])
          ?.toString(),
      pdfStoragePath: (json['pdf_storage_path'] ?? json['pdfStoragePath'])
          ?.toString(),
    );
  }

  Map<String, dynamic> toDatabaseRow() => {
    'id': id,
    'category_id': categoryId,
    'title': title,
    'certificate_number': certificateNumber,
    'verification_code': verificationCode,
    'status': status.databaseValue,
    'issued_at': issuedAt?.toIso8601String(),
    'signed_at': signedAt?.toIso8601String(),
    'signer_name': signerName,
    'signature_hash': signatureHash,
    'pdf_storage_path': pdfStoragePath,
  };
}
