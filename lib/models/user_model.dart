import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk data user/pengguna
class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String role; // "admin" atau "karyawan"
  final bool approved;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
    required this.approved,
    required this.createdAt,
  });

  /// Factory untuk membuat UserModel dari Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'karyawan',
      approved: data['approved'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert ke Map untuk disimpan di Firestore
  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'email': email,
      'role': role,
      'approved': approved,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Copy dengan perubahan field tertentu
  UserModel copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? role,
    bool? approved,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      role: role ?? this.role,
      approved: approved ?? this.approved,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isKaryawan => role == 'karyawan';
}
