import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk request pengambilan barang
class RequestModel {
  final String id;
  final String userId;
  final String productId;
  final int qty;
  final String status; // "queued", "processing", "done", "rejected"
  final DateTime createdAt;
  final DateTime? processedAt;
  final String note;
  final String? rejectReason;

  RequestModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.qty,
    required this.status,
    required this.createdAt,
    this.processedAt,
    required this.note,
    this.rejectReason,
  });

  /// Factory untuk membuat RequestModel dari Firestore document
  factory RequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RequestModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      productId: data['productId'] ?? '',
      qty: data['qty'] ?? 0,
      status: data['status'] ?? 'queued',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      processedAt: (data['processedAt'] as Timestamp?)?.toDate(),
      note: data['note'] ?? '',
      rejectReason: data['rejectReason'],
    );
  }

  /// Convert ke Map untuk disimpan di Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'productId': productId,
      'qty': qty,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'processedAt': processedAt != null
          ? Timestamp.fromDate(processedAt!)
          : null,
      'note': note,
      'rejectReason': rejectReason,
    };
  }

  /// Copy dengan perubahan field tertentu
  RequestModel copyWith({
    String? id,
    String? userId,
    String? productId,
    int? qty,
    String? status,
    DateTime? createdAt,
    DateTime? processedAt,
    String? note,
    String? rejectReason,
  }) {
    return RequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      qty: qty ?? this.qty,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
      note: note ?? this.note,
      rejectReason: rejectReason ?? this.rejectReason,
    );
  }

  bool get isQueued => status == 'queued';
  bool get isProcessing => status == 'processing';
  bool get isDone => status == 'done';
  bool get isRejected => status == 'rejected';
}
