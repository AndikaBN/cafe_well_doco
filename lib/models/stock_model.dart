import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk log penambahan stok (stock in)
class StockInModel {
  final String id;
  final String productId;
  final int qty;
  final String adminId;
  final DateTime timestamp;
  final String note;

  StockInModel({
    required this.id,
    required this.productId,
    required this.qty,
    required this.adminId,
    required this.timestamp,
    required this.note,
  });

  /// Factory untuk membuat StockInModel dari Firestore document
  factory StockInModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockInModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      qty: data['qty'] ?? 0,
      adminId: data['adminId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: data['note'] ?? '',
    );
  }

  /// Convert ke Map untuk disimpan di Firestore
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'qty': qty,
      'adminId': adminId,
      'timestamp': FieldValue.serverTimestamp(),
      'note': note,
    };
  }
}

/// Model untuk log pengurangan stok (stock out)
class StockOutModel {
  final String id;
  final String productId;
  final int qty;
  final String userId;
  final DateTime timestamp;
  final String note;

  StockOutModel({
    required this.id,
    required this.productId,
    required this.qty,
    required this.userId,
    required this.timestamp,
    required this.note,
  });

  /// Factory untuk membuat StockOutModel dari Firestore document
  factory StockOutModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockOutModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      qty: data['qty'] ?? 0,
      userId: data['userId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: data['note'] ?? '',
    );
  }

  /// Convert ke Map untuk disimpan di Firestore
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'qty': qty,
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
      'note': note,
    };
  }
}
