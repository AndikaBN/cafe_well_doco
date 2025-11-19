import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk data produk
class ProductModel {
  final String id;
  final String name;
  final int stock;
  final String unit; // satuan: "kg", "liter", "pcs", dll
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.stock,
    required this.unit,
    required this.updatedAt,
  });

  /// Factory untuk membuat ProductModel dari Firestore document
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      stock: data['stock'] ?? 0,
      unit: data['unit'] ?? 'pcs',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert ke Map untuk disimpan di Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'stock': stock,
      'unit': unit,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Copy dengan perubahan field tertentu
  ProductModel copyWith({
    String? id,
    String? name,
    int? stock,
    String? unit,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      stock: stock ?? this.stock,
      unit: unit ?? this.unit,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
