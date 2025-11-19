import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk kode undangan karyawan
class InviteModel {
  final String code;
  final String createdByAdminId;
  final String role;
  final DateTime createdAt;
  final DateTime? validUntil;
  final bool used;
  final String? usedBy;

  InviteModel({
    required this.code,
    required this.createdByAdminId,
    required this.role,
    required this.createdAt,
    this.validUntil,
    this.used = false,
    this.usedBy,
  });

  /// Factory untuk membuat InviteModel dari Firestore document
  factory InviteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InviteModel(
      code: doc.id,
      createdByAdminId: data['createdByAdminId'] ?? '',
      role: data['role'] ?? 'karyawan',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      validUntil: (data['validUntil'] as Timestamp?)?.toDate(),
      used: data['used'] ?? false,
      usedBy: data['usedBy'],
    );
  }

  /// Convert ke Map untuk disimpan di Firestore
  Map<String, dynamic> toJson() {
    return {
      'createdByAdminId': createdByAdminId,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      'validUntil': validUntil != null ? Timestamp.fromDate(validUntil!) : null,
      'used': used,
      'usedBy': usedBy,
    };
  }

  /// Cek apakah kode masih valid
  bool get isValid {
    if (used) return false;
    if (validUntil != null && DateTime.now().isAfter(validUntil!)) {
      return false;
    }
    return true;
  }
}
