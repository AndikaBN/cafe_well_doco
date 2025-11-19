import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/stock_model.dart';
import '../models/request_model.dart';
import '../models/invite_model.dart';
import '../models/user_model.dart';

/// Service untuk handle operasi Firestore
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== PRODUCTS ====================

  /// Stream untuk monitor semua produk
  Stream<List<ProductModel>> getProductsStream() {
    return _firestore
        .collection('products')
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Ambil satu produk
  Future<ProductModel?> getProduct(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists) {
        return ProductModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Tambah produk baru (admin only)
  Future<Map<String, dynamic>> addProduct({
    required String name,
    required int stock,
    required String unit,
  }) async {
    try {
      final product = ProductModel(
        id: '',
        name: name,
        stock: stock,
        unit: unit,
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('products').add(product.toJson());

      return {'success': true, 'message': 'Produk berhasil ditambahkan'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal menambahkan produk: ${e.toString()}',
      };
    }
  }

  /// Update produk (admin only)
  Future<Map<String, dynamic>> updateProduct({
    required String productId,
    required String name,
    required String unit,
  }) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'name': name,
        'unit': unit,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'Produk berhasil diupdate'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal mengupdate produk: ${e.toString()}',
      };
    }
  }

  /// Hapus produk (admin only)
  Future<Map<String, dynamic>> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();

      return {'success': true, 'message': 'Produk berhasil dihapus'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal menghapus produk: ${e.toString()}',
      };
    }
  }

  // ==================== STOCK IN (Admin) ====================

  /// Tambah stok dengan transaction (atomic operation)
  /// Admin menambahkan stok ke produk
  Future<Map<String, dynamic>> addStock({
    required String productId,
    required int qty,
    required String adminId,
    required String note,
  }) async {
    try {
      // Gunakan transaction untuk atomic operation
      await _firestore.runTransaction((transaction) async {
        final productRef = _firestore.collection('products').doc(productId);
        final productSnapshot = await transaction.get(productRef);

        if (!productSnapshot.exists) {
          throw Exception('Produk tidak ditemukan');
        }

        final currentStock = productSnapshot.data()!['stock'] as int;
        final newStock = currentStock + qty;

        // Update stock produk
        transaction.update(productRef, {
          'stock': newStock,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Buat log stock_in
        final stockInRef = _firestore.collection('stock_in').doc();
        transaction.set(stockInRef, {
          'productId': productId,
          'qty': qty,
          'adminId': adminId,
          'timestamp': FieldValue.serverTimestamp(),
          'note': note,
        });
      });

      return {'success': true, 'message': 'Stok berhasil ditambahkan'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal menambahkan stok: ${e.toString()}',
      };
    }
  }

  /// Stream untuk monitor log stock in
  Stream<List<StockInModel>> getStockInStream() {
    return _firestore
        .collection('stock_in')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StockInModel.fromFirestore(doc))
              .toList(),
        );
  }

  // ==================== REQUESTS ====================

  /// Buat request baru (karyawan)
  /// Menggunakan OPSI A: Langsung proses dengan transaction
  Future<Map<String, dynamic>> createRequestDirect({
    required String userId,
    required String productId,
    required int qty,
    required String note,
  }) async {
    try {
      String? requestId;

      // Gunakan transaction untuk atomic operation
      await _firestore.runTransaction((transaction) async {
        final productRef = _firestore.collection('products').doc(productId);
        final productSnapshot = await transaction.get(productRef);

        if (!productSnapshot.exists) {
          throw Exception('Produk tidak ditemukan');
        }

        final currentStock = productSnapshot.data()!['stock'] as int;

        if (currentStock < qty) {
          throw Exception('Stok tidak mencukupi. Stok tersedia: $currentStock');
        }

        final newStock = currentStock - qty;

        // Update stock produk
        transaction.update(productRef, {
          'stock': newStock,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Buat log stock_out
        final stockOutRef = _firestore.collection('stock_out').doc();
        transaction.set(stockOutRef, {
          'productId': productId,
          'qty': qty,
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
          'note': note,
        });

        // Buat request dengan status done
        final requestRef = _firestore.collection('requests').doc();
        requestId = requestRef.id;
        transaction.set(requestRef, {
          'userId': userId,
          'productId': productId,
          'qty': qty,
          'status': 'done',
          'createdAt': FieldValue.serverTimestamp(),
          'processedAt': FieldValue.serverTimestamp(),
          'note': note,
          'rejectReason': null,
        });
      });

      return {
        'success': true,
        'message': 'Request berhasil diproses',
        'requestId': requestId,
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  /// Buat request dengan status queued (OPSI B: admin processing)
  /// Request akan masuk antrian dan diproses manual oleh admin
  Future<Map<String, dynamic>> createRequestQueued({
    required String userId,
    required String productId,
    required int qty,
    required String note,
  }) async {
    try {
      final request = RequestModel(
        id: '',
        userId: userId,
        productId: productId,
        qty: qty,
        status: 'queued',
        createdAt: DateTime.now(),
        note: note,
      );

      final docRef = await _firestore
          .collection('requests')
          .add(request.toJson());

      return {
        'success': true,
        'message': 'Request berhasil dibuat. Menunggu admin memproses.',
        'requestId': docRef.id,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal membuat request: ${e.toString()}',
      };
    }
  }

  /// Proses request (admin) - untuk OPSI B
  /// Admin memproses request yang ada di antrian
  Future<Map<String, dynamic>> processRequest({
    required String requestId,
    required bool approve,
    String? rejectReason,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final requestRef = _firestore.collection('requests').doc(requestId);
        final requestSnapshot = await transaction.get(requestRef);

        if (!requestSnapshot.exists) {
          throw Exception('Request tidak ditemukan');
        }

        final requestData = requestSnapshot.data()!;
        final productId = requestData['productId'] as String;
        final qty = requestData['qty'] as int;
        final userId = requestData['userId'] as String;
        final note = requestData['note'] as String? ?? '';

        if (approve) {
          // Cek dan kurangi stok
          final productRef = _firestore.collection('products').doc(productId);
          final productSnapshot = await transaction.get(productRef);

          if (!productSnapshot.exists) {
            throw Exception('Produk tidak ditemukan');
          }

          final currentStock = productSnapshot.data()!['stock'] as int;

          if (currentStock < qty) {
            throw Exception(
              'Stok tidak mencukupi. Stok tersedia: $currentStock',
            );
          }

          final newStock = currentStock - qty;

          // Update stock produk
          transaction.update(productRef, {
            'stock': newStock,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Buat log stock_out
          final stockOutRef = _firestore.collection('stock_out').doc();
          transaction.set(stockOutRef, {
            'productId': productId,
            'qty': qty,
            'userId': userId,
            'timestamp': FieldValue.serverTimestamp(),
            'note': note,
          });

          // Update request status
          transaction.update(requestRef, {
            'status': 'done',
            'processedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Reject request
          transaction.update(requestRef, {
            'status': 'rejected',
            'processedAt': FieldValue.serverTimestamp(),
            'rejectReason': rejectReason ?? 'Ditolak oleh admin',
          });
        }
      });

      return {
        'success': true,
        'message': approve ? 'Request berhasil disetujui' : 'Request ditolak',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  /// Stream untuk monitor requests (semua)
  Stream<List<RequestModel>> getRequestsStream({
    String? userId,
    String? status,
  }) {
    Query query = _firestore.collection('requests');

    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RequestModel.fromFirestore(doc))
              .toList(),
        );
  }

  // ==================== USERS (Admin) ====================

  /// Stream untuk monitor semua users
  Stream<List<UserModel>> getUsersStream({bool? approved}) {
    Query query = _firestore.collection('users');

    if (approved != null) {
      query = query.where('approved', isEqualTo: approved);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList(),
        );
  }

  /// Approve atau reject user (admin only)
  Future<Map<String, dynamic>> updateUserApproval({
    required String userId,
    required bool approved,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'approved': approved,
      });

      return {
        'success': true,
        'message': approved ? 'User berhasil disetujui' : 'User ditolak',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal mengupdate status user: ${e.toString()}',
      };
    }
  }

  // ==================== INVITES (Admin) ====================

  /// Buat kode undangan baru
  Future<Map<String, dynamic>> createInvite({
    required String adminId,
    required String role,
    DateTime? validUntil,
  }) async {
    try {
      // Generate kode unik (6 karakter)
      final code = _generateInviteCode();

      final invite = InviteModel(
        code: code,
        createdByAdminId: adminId,
        role: role,
        createdAt: DateTime.now(),
        validUntil: validUntil,
      );

      await _firestore.collection('invites').doc(code).set(invite.toJson());

      return {
        'success': true,
        'message': 'Kode undangan berhasil dibuat',
        'code': code,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal membuat kode undangan: ${e.toString()}',
      };
    }
  }

  /// Generate kode invite acak
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    var code = '';

    for (int i = 0; i < 6; i++) {
      code += chars[(random + i) % chars.length];
    }

    return code;
  }

  /// Stream untuk monitor invites
  Stream<List<InviteModel>> getInvitesStream() {
    return _firestore
        .collection('invites')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InviteModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Hapus invite
  Future<Map<String, dynamic>> deleteInvite(String code) async {
    try {
      await _firestore.collection('invites').doc(code).delete();

      return {'success': true, 'message': 'Kode undangan berhasil dihapus'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal menghapus kode undangan: ${e.toString()}',
      };
    }
  }
}
