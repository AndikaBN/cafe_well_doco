import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Service untuk handle authentication dan user management
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream untuk monitor perubahan auth state
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// User yang sedang login
  User? get currentUser => _auth.currentUser;

  /// Register user baru dengan email dan password
  /// Membuat dokumen users/{uid} dengan approved = false
  Future<Map<String, dynamic>> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    String? inviteCode,
  }) async {
    try {
      // Validasi invite code jika ada
      String role = 'karyawan';
      if (inviteCode != null && inviteCode.isNotEmpty) {
        final inviteDoc = await _firestore
            .collection('invites')
            .doc(inviteCode)
            .get();

        if (!inviteDoc.exists) {
          return {'success': false, 'message': 'Kode undangan tidak valid'};
        }

        final inviteData = inviteDoc.data()!;
        final used = inviteData['used'] ?? false;
        final validUntil = (inviteData['validUntil'] as Timestamp?)?.toDate();

        if (used) {
          return {'success': false, 'message': 'Kode undangan sudah digunakan'};
        }

        if (validUntil != null && DateTime.now().isAfter(validUntil)) {
          return {
            'success': false,
            'message': 'Kode undangan sudah kadaluarsa',
          };
        }

        role = inviteData['role'] ?? 'karyawan';
      }

      // Buat akun Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // Buat dokumen user di Firestore
      final userData = UserModel(
        uid: uid,
        displayName: displayName,
        email: email,
        role: role,
        approved: false, // Default belum approved
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set(userData.toJson());

      // Tandai invite code sebagai used jika ada
      if (inviteCode != null && inviteCode.isNotEmpty) {
        await _firestore.collection('invites').doc(inviteCode).update({
          'used': true,
          'usedBy': uid,
        });
      }

      // Sign out karena user belum approved
      await _auth.signOut();

      return {
        'success': true,
        'message': 'Registrasi berhasil! Menunggu persetujuan admin.',
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Terjadi kesalahan';

      if (e.code == 'weak-password') {
        message = 'Password terlalu lemah';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email sudah terdaftar';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  /// Login dengan email dan password
  /// Validasi apakah user sudah approved
  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Login ke Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // Cek approval status
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        await _auth.signOut();
        return {'success': false, 'message': 'Data user tidak ditemukan'};
      }

      final userData = UserModel.fromFirestore(userDoc);

      if (!userData.approved) {
        await _auth.signOut();
        return {
          'success': false,
          'message':
              'Akun menunggu persetujuan admin. Silakan hubungi admin untuk aktivasi.',
        };
      }

      return {'success': true, 'message': 'Login berhasil', 'user': userData};
    } on FirebaseAuthException catch (e) {
      String message = 'Terjadi kesalahan';

      if (e.code == 'user-not-found') {
        message = 'Email tidak terdaftar';
      } else if (e.code == 'wrong-password') {
        message = 'Password salah';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid';
      } else if (e.code == 'user-disabled') {
        message = 'Akun telah dinonaktifkan';
      } else if (e.code == 'invalid-credential') {
        message = 'Email atau password salah';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Ambil data user dari Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Stream untuk monitor perubahan data user
  Stream<UserModel?> userDataStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }
}
