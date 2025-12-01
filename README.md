# Coffee Well Doco - Inventory Management System

Sistem Manajemen Inventori berbasis mobile untuk Coffee Well Doco menggunakan Flutter dan Firebase.

## 📱 Tentang Aplikasi

Aplikasi inventory management ini dirancang untuk mengelola stok bahan baku Coffee Well Doco dengan fitur:
- Manajemen pengguna berbasis role (Admin & Karyawan)
- Pencatatan barang masuk dan keluar
- Sistem approval untuk registrasi user
- Laporan pengambilan barang dengan export PDF
- Auto-login dan Remember Me
- UI tema dark coffee yang elegan

## 🛠️ Teknologi yang Digunakan

- **Framework**: Flutter SDK 3.9.0+
- **Bahasa**: Dart
- **Backend**: Firebase (Free Tier)
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Core
- **State Management**: Provider 6.1.5+1
- **Local Storage**: SharedPreferences 2.5.3
- **PDF Generation**: pdf 3.11.3, printing 5.14.2
- **Date Formatting**: intl 0.20.2

## 📁 Struktur Project

```
lib/
├── main.dart                          # Entry point aplikasi
├── models/                            # Data models
│   ├── user_model.dart               # Model user (admin/karyawan)
│   ├── product_model.dart            # Model produk/bahan
│   ├── stock_model.dart              # Model stock in/out
│   ├── request_model.dart            # Model request barang
│   └── invite_model.dart             # Model kode undangan
├── services/                          # Business logic layer
│   ├── auth_service.dart             # Service autentikasi
│   └── firestore_service.dart        # Service database operations
├── providers/                         # State management
│   └── theme_provider.dart           # Provider tema dark/light
├── theme/                            # Theme configuration
│   └── app_colors.dart               # Color palette coffee theme
├── pages/                            # UI Screens
│   ├── splash_page.dart              # Splash screen & auto-login
│   ├── login_page.dart               # Halaman login
│   ├── register_page.dart            # Halaman registrasi
│   ├── admin_home_page.dart          # Dashboard admin
│   ├── karyawan_home_page.dart       # Dashboard karyawan
│   ├── product_management_page.dart   # CRUD produk (Admin)
│   ├── stock_in_page.dart            # Input barang masuk (Admin)
│   ├── create_request_page.dart      # Request barang (Karyawan)
│   ├── my_requests_page.dart         # Riwayat request (Karyawan)
│   ├── requests_management_page.dart  # Kelola request (Admin)
│   ├── user_approval_page.dart       # Approval user (Admin)
│   ├── invites_page.dart             # Kelola kode undangan (Admin)
│   ├── reports_page.dart             # Laporan & export PDF (Admin)
│   └── sample_data_seeder_page.dart  # Generate data sample (Admin)
└── firebase_options.dart              # Firebase configuration
```

## 🔐 Fitur Autentikasi

### 1. Register (Registrasi User Baru)

**File**: `lib/pages/register_page.dart`

**Logika**:
```dart
Future<void> _register() async {
  // Validasi form
  if (!_formKey.currentState!.validate()) return;
  if (!_agreeTerms) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Anda harus menyetujui syarat dan ketentuan')),
    );
    return;
  }

  setState(() => _loading = true);

  // Panggil AuthService
  final result = await _authService.registerWithEmail(
    email: _email.text.trim(),
    password: _password.text.trim(),
    displayName: _fullName.text.trim(),
    inviteCode: _inviteCode.text.trim().isEmpty ? null : _inviteCode.text.trim(),
  );

  setState(() => _loading = false);

  if (result['success']) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrasi berhasil! Menunggu persetujuan admin.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  } else {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }
}
```

**Service Logic** (`lib/services/auth_service.dart`):
```dart
Future<Map<String, dynamic>> registerWithEmail({
  required String email,
  required String password,
  required String displayName,
  String? inviteCode,
}) async {
  try {
    // 1. Validasi invite code (opsional)
    String role = 'karyawan';
    if (inviteCode != null && inviteCode.isNotEmpty) {
      final inviteDoc = await _firestore.collection('invites').doc(inviteCode).get();
      if (!inviteDoc.exists) {
        return {'success': false, 'message': 'Kode undangan tidak valid'};
      }
      final inviteData = inviteDoc.data()!;
      final validUntil = inviteData['validUntil'] as Timestamp?;
      
      if (validUntil != null && validUntil.toDate().isBefore(DateTime.now())) {
        return {'success': false, 'message': 'Kode undangan sudah kadaluarsa'};
      }
      
      role = inviteData['role'] ?? 'karyawan';
    }

    // 2. Buat akun Firebase Authentication
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 3. Update display name di Firebase Auth
    await credential.user?.updateDisplayName(displayName);

    // 4. Buat dokumen user di Firestore
    await _firestore.collection('users').doc(credential.user!.uid).set({
      'displayName': displayName,
      'email': email,
      'role': role,
      'approved': false, // Default: menunggu approval admin
      'createdAt': FieldValue.serverTimestamp(),
    });

    return {'success': true, 'message': 'Registrasi berhasil'};
  } catch (e) {
    return {'success': false, 'message': 'Terjadi kesalahan: $e'};
  }
}
```

**Penjelasan**:
- User mengisi form registrasi (nama, email, password, kode undangan opsional)
- Sistem validasi kode undangan jika diisi (menentukan role: admin/karyawan)
- Buat akun di Firebase Authentication
- Buat dokumen user di Firestore dengan status `approved: false`
- User harus menunggu admin untuk approve akun sebelum bisa login

---

### 2. Login (Masuk ke Aplikasi)

**File**: `lib/pages/login_page.dart`

**Logika**:
```dart
Future<void> _login() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _loading = true);

  // Panggil AuthService untuk sign in
  final result = await _authService.signInWithEmail(
    email: _email.text.trim(),
    password: _password.text.trim(),
  );

  setState(() => _loading = false);

  if (result['success']) {
    final user = result['user'] as UserModel;

    // Cek apakah user sudah diapprove admin
    if (!user.approved) {
      await _authService.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akun Anda menunggu persetujuan admin'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Simpan credentials jika "Remember Me" aktif
    if (_rememberMe) {
      await _saveCredentials();
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
    }

    // Redirect ke halaman sesuai role
    if (mounted) {
      if (user.role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHomePage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const KaryawanHomePage()),
        );
      }
    }
  } else {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }
}
```

**Service Logic**:
```dart
Future<Map<String, dynamic>> signInWithEmail({
  required String email,
  required String password,
}) async {
  try {
    // 1. Login menggunakan Firebase Authentication
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 2. Ambil data user dari Firestore
    final userDoc = await _firestore
        .collection('users')
        .doc(credential.user!.uid)
        .get();
    
    if (!userDoc.exists) {
      await _auth.signOut();
      return {'success': false, 'message': 'Data pengguna tidak ditemukan'};
    }

    final user = UserModel.fromFirestore(userDoc);

    // 3. Validasi status approval
    if (!user.approved) {
      return {
        'success': false,
        'message': 'Akun Anda menunggu persetujuan admin'
      };
    }

    return {'success': true, 'user': user};
  } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found' || e.code == 'wrong-password') {
      return {'success': false, 'message': 'Email atau password salah'};
    }
    return {'success': false, 'message': 'Error: ${e.message}'};
  } catch (e) {
    return {'success': false, 'message': 'Terjadi kesalahan: $e'};
  }
}
```

**Fitur Remember Me**:
```dart
Future<void> _saveCredentials() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('saved_email', _email.text.trim());
  await prefs.setString('saved_password', _password.text.trim());
  await prefs.setBool('remember_me', true);
}

Future<void> _loadRememberedCredentials() async {
  final prefs = await SharedPreferences.getInstance();
  final rememberMe = prefs.getBool('remember_me') ?? false;
  
  if (rememberMe) {
    _email.text = prefs.getString('saved_email') ?? '';
    _password.text = prefs.getString('saved_password') ?? '';
    setState(() => _rememberMe = true);
  }
}
```

**Auto-Login** (`lib/pages/splash_page.dart`):
```dart
Future<void> _checkAuthState() async {
  await Future.delayed(const Duration(seconds: 2));

  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) {
    // Belum login -> ke halaman login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
    return;
  }

  // Sudah login -> ambil data user dari Firestore
  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser.uid)
      .get();

  if (!userDoc.exists) {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
    return;
  }

  final user = UserModel.fromFirestore(userDoc);

  // Redirect berdasarkan role
  if (user.role == 'admin') {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AdminHomePage()),
    );
  } else {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const KaryawanHomePage()),
    );
  }
}
```

---

## 📦 Fitur Manajemen Stok

### 3. Barang Masuk (Stock In)

**File**: `lib/pages/stock_in_page.dart`

**Logika**:
```dart
Future<void> _submitStockIn() async {
  if (!_formKey.currentState!.validate() || _selectedProduct == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lengkapi semua field')),
    );
    return;
  }

  setState(() => _loading = true);

  final qty = int.parse(_qtyController.text);
  final adminId = FirebaseAuth.instance.currentUser!.uid;

  // Panggil FirestoreService untuk tambah stok
  final result = await _firestoreService.addStockIn(
    productId: _selectedProduct!.id,
    qty: qty,
    adminId: adminId,
    note: _noteController.text.trim(),
  );

  setState(() => _loading = false);

  if (mounted) {
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stok berhasil ditambahkan'),
          backgroundColor: Colors.green,
        ),
      );
      // Reset form
      _qtyController.clear();
      _noteController.clear();
      setState(() => _selectedProduct = null);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

**Service Logic** (`lib/services/firestore_service.dart`):
```dart
Future<Map<String, dynamic>> addStockIn({
  required String productId,
  required int qty,
  required String adminId,
  String? note,
}) async {
  try {
    // Gunakan Firestore Transaction untuk atomic operation
    return await _firestore.runTransaction((transaction) async {
      // 1. Ambil document produk
      final productRef = _firestore.collection('products').doc(productId);
      final productDoc = await transaction.get(productRef);

      if (!productDoc.exists) {
        throw Exception('Produk tidak ditemukan');
      }

      // 2. Hitung stok baru
      final currentStock = productDoc.data()!['stock'] as int;
      final newStock = currentStock + qty;

      // 3. Update stok produk
      transaction.update(productRef, {
        'stock': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 4. Buat log stock_in untuk tracking
      final stockInRef = _firestore.collection('stock_in').doc();
      transaction.set(stockInRef, {
        'productId': productId,
        'qty': qty,
        'adminId': adminId,
        'timestamp': FieldValue.serverTimestamp(),
        'note': note ?? '',
      });

      return {'success': true, 'message': 'Stok berhasil ditambahkan'};
    });
  } catch (e) {
    return {
      'success': false,
      'message': 'Gagal menambah stok: ${e.toString()}'
    };
  }
}
```

**Penjelasan**:
- Admin memilih produk dari dropdown
- Input jumlah barang yang masuk
- Menggunakan **Firestore Transaction** untuk:
  1. Update stok produk (menambah)
  2. Membuat log di collection `stock_in`
- Transaction memastikan operasi atomic (sukses semua atau gagal semua)

---

### 4. Barang Keluar (Request Barang oleh Karyawan)

**File**: `lib/pages/create_request_page.dart`

**Logika**:
```dart
Future<void> _submitRequest() async {
  if (!_formKey.currentState!.validate() || _selectedProduct == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lengkapi semua field')),
    );
    return;
  }

  // Validasi stok tersedia
  final qty = int.parse(_qtyController.text);
  if (_selectedProduct!.stock < qty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Stok tidak cukup! Tersedia: ${_selectedProduct!.stock} ${_selectedProduct!.unit}',
        ),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  setState(() => _loading = true);

  final userId = FirebaseAuth.instance.currentUser!.uid;

  // OPSI A: Direct processing (langsung kurangi stok)
  final result = await _firestoreService.createRequestDirect(
    userId: userId,
    productId: _selectedProduct!.id,
    qty: qty,
    note: _noteController.text.trim(),
  );

  setState(() => _loading = false);

  if (mounted) {
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request berhasil diproses'),
          backgroundColor: Colors.green,
        ),
      );
      // Reset form
      _qtyController.clear();
      _noteController.clear();
      setState(() => _selectedProduct = null);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

**Service Logic - Direct Processing**:
```dart
Future<Map<String, dynamic>> createRequestDirect({
  required String userId,
  required String productId,
  required int qty,
  String? note,
}) async {
  try {
    String? requestId;

    // Gunakan Firestore Transaction untuk atomic operation
    await _firestore.runTransaction((transaction) async {
      // 1. Ambil document produk
      final productRef = _firestore.collection('products').doc(productId);
      final productSnapshot = await transaction.get(productRef);

      if (!productSnapshot.exists) {
        throw Exception('Produk tidak ditemukan');
      }

      final currentStock = productSnapshot.data()!['stock'] as int;

      // 2. Validasi stok mencukupi
      if (currentStock < qty) {
        throw Exception(
          'Stok tidak mencukupi. Stok tersedia: $currentStock'
        );
      }

      final newStock = currentStock - qty;

      // 3. Update stok produk (mengurangi)
      transaction.update(productRef, {
        'stock': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 4. Buat log stock_out untuk tracking pengambilan
      final stockOutRef = _firestore.collection('stock_out').doc();
      transaction.set(stockOutRef, {
        'productId': productId,
        'qty': qty,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'note': note ?? '',
      });

      // 5. Buat request dengan status 'done' (langsung selesai)
      final requestRef = _firestore.collection('requests').doc();
      requestId = requestRef.id;
      transaction.set(requestRef, {
        'userId': userId,
        'productId': productId,
        'qty': qty,
        'status': 'done',
        'createdAt': FieldValue.serverTimestamp(),
        'processedAt': FieldValue.serverTimestamp(),
        'note': note ?? '',
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
```

**Penjelasan**:
- Karyawan memilih produk dan input jumlah
- Sistem validasi stok tersedia
- **OPSI A (Direct)**: Langsung kurangi stok, buat stock_out, status request = done
- Menggunakan Transaction untuk operasi atomic

---

## 👥 Fitur Manajemen User

### 5. Approval User

**File**: `lib/pages/user_approval_page.dart`

**Logika**:
```dart
Future<void> _approveUser(String userId, bool approve) async {
  try {
    // Update field 'approved' di Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'approved': approve});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve 
                ? 'User berhasil disetujui' 
                : 'User berhasil ditolak'
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

**Stream untuk Monitor User**:
```dart
Stream<List<UserModel>> getUsersStream({bool? approved}) {
  Query query = _firestore.collection('users');

  if (approved != null) {
    query = query.where('approved', isEqualTo: approved);
  }

  // Tidak pakai orderBy di query untuk avoid composite index
  return query.snapshots().map((snapshot) {
    final users = snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .toList();

    // Sorting di client-side (descending by createdAt)
    users.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return users;
  });
}
```

**Penjelasan**:
- Admin melihat daftar user dengan `approved: false`
- Menggunakan StreamBuilder untuk real-time updates
- Admin bisa approve (set `approved: true`) atau reject (hapus user)
- Sorting dilakukan di client-side untuk menghindari composite index Firebase

---

## 📊 Fitur Laporan

### 6. Laporan Pengambilan Barang

**File**: `lib/pages/reports_page.dart`

**Load Data**:
```dart
Future<void> _loadData() async {
  setState(() => _loading = true);

  // Ambil semua stock out dalam range tanggal
  final stream = _firestoreService.getStockOutStream();
  final allData = await stream.first;

  // Normalisasi tanggal untuk filter yang tepat
  final startOfDay = DateTime(
    _startDate!.year,
    _startDate!.month,
    _startDate!.day,
  );
  final endOfDay = DateTime(
    _endDate!.year,
    _endDate!.month,
    _endDate!.day,
    23,
    59,
    59,
  );

  // Filter berdasarkan tanggal
  final filtered = allData.where((item) {
    return !item.timestamp.isBefore(startOfDay) &&
        !item.timestamp.isAfter(endOfDay);
  }).toList();

  // Sort by timestamp descending (terbaru dulu)
  filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

  setState(() {
    _filteredData = filtered;
    _loading = false;
  });
}
```

**Generate PDF**:
```dart
Future<void> _generatePDF() async {
  if (_filteredData == null || _filteredData!.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tidak ada data untuk diekspor'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final pdf = pw.Document();
    final List<Map<String, dynamic>> reportData = [];

    // Ambil data lengkap untuk setiap stock out
    for (var stockOut in _filteredData!) {
      final user = await _firestoreService.getUserById(stockOut.userId);
      final product = await _firestoreService.getProduct(stockOut.productId);

      if (user != null && product != null) {
        // Hitung stok sebelum diambil
        final stockBeforeOut = product.stock + stockOut.qty;

        reportData.add({
          'karyawan': user.displayName,
          'tanggal': DateFormat('dd/MM/yyyy HH:mm').format(stockOut.timestamp),
          'bahanMasuk': DateFormat('dd/MM/yyyy HH:mm').format(product.updatedAt),
          'jumlahMasuk': '$stockBeforeOut ${product.unit}',
          'bahanKeluar': product.name,
          'jumlahKeluar': '${stockOut.qty} ${product.unit}',
          'stok': '${product.stock} ${product.unit}',
        });
      }
    }

    // Build PDF dengan 7 kolom
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'LAPORAN PENGAMBILAN BARANG',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Coffee Well Doco - Inventory Management',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Divider(thickness: 2),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Tabel Data (7 kolom)
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                children: [
                  _buildTableCell('Karyawan', isHeader: true),
                  _buildTableCell('Tanggal', isHeader: true),
                  _buildTableCell('Bahan Masuk', isHeader: true),
                  _buildTableCell('Jumlah Masuk', isHeader: true),
                  _buildTableCell('Bahan Keluar', isHeader: true),
                  _buildTableCell('Jumlah Keluar', isHeader: true),
                  _buildTableCell('Stok', isHeader: true),
                ],
              ),
              // Data rows
              ...reportData.map(
                (data) => pw.TableRow(
                  children: [
                    _buildTableCell(data['karyawan']),
                    _buildTableCell(data['tanggal']),
                    _buildTableCell(data['bahanMasuk']),
                    _buildTableCell(data['jumlahMasuk']),
                    _buildTableCell(data['bahanKeluar']),
                    _buildTableCell(data['jumlahKeluar']),
                    _buildTableCell(data['stok']),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // Close loading dialog
    if (mounted) Navigator.of(context).pop();

    // Tampilkan preview PDF dan opsi print/save
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Laporan_Pengambilan_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  } catch (e) {
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generate PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

**Backfill Stock Out (Regenerate Missing Data)**:
```dart
Future<Map<String, dynamic>> backfillStockOut() async {
  try {
    int created = 0;
    int skipped = 0;

    // Ambil semua request dengan status 'done'
    final requestsSnapshot = await _firestore
        .collection('requests')
        .where('status', isEqualTo: 'done')
        .get();

    // Proses setiap request
    for (var requestDoc in requestsSnapshot.docs) {
      final data = requestDoc.data();
      final userId = data['userId'] as String;
      final productId = data['productId'] as String;
      final qty = data['qty'] as int;
      final processedAt = data['processedAt'] as Timestamp?;

      if (processedAt == null) {
        skipped++;
        continue;
      }

      // Buat stock_out baru
      await _firestore.collection('stock_out').add({
        'productId': productId,
        'qty': qty,
        'userId': userId,
        'timestamp': processedAt,
        'note': data['note'] ?? '',
      });

      created++;
    }

    return {
      'success': true,
      'message': 'Backfill selesai. Dibuat: $created',
      'created': created,
    };
  } catch (e) {
    return {
      'success': false,
      'message': 'Gagal backfill: ${e.toString()}',
    };
  }
}
```

**Penjelasan**:
- Admin memilih periode tanggal untuk laporan
- Sistem query collection `stock_out` dan filter by tanggal
- Generate PDF dengan 7 kolom tabel
- Fitur backfill untuk regenerate data stock_out yang hilang

---

## 🔐 Firebase Security Rules

**File**: `firestore.rules`

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isAdmin() {
      return isSignedIn() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin' &&
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.approved == true;
    }
    
    function isApprovedKaryawan() {
      return isSignedIn() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.approved == true;
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn() && request.auth.uid == userId;
      allow update: if isAdmin() || request.auth.uid == userId;
      allow delete: if isAdmin();
    }
    
    // Products collection
    match /products/{productId} {
      allow read: if isSignedIn();
      allow create, update, delete: if isAdmin();
      // Allow karyawan to update stock field only
      allow update: if isApprovedKaryawan() && 
                      request.resource.data.diff(resource.data).affectedKeys().hasOnly(['stock', 'updatedAt']);
    }
    
    // Stock In collection
    match /stock_in/{stockInId} {
      allow read: if isSignedIn();
      allow create: if isAdmin();
      allow update, delete: if false; // Immutable logs
    }
    
    // Stock Out collection
    match /stock_out/{stockOutId} {
      allow read: if isSignedIn();
      allow create: if isApprovedKaryawan();
      allow update, delete: if false; // Immutable logs
    }
    
    // Requests collection
    match /requests/{requestId} {
      allow read: if isSignedIn();
      allow create: if isApprovedKaryawan();
      allow update: if isAdmin();
      allow delete: if isAdmin();
    }
    
    // Invites collection
    match /invites/{inviteCode} {
      allow read: if isSignedIn();
      allow create, update, delete: if isAdmin();
    }
  }
}
```

---

## 📱 Cara Menjalankan Aplikasi

### 1. Prerequisites
```bash
# Install Flutter SDK
# Download dari: https://docs.flutter.dev/get-started/install

# Verifikasi instalasi
flutter doctor
```

### 2. Setup Firebase
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login Firebase
firebase login

# Initialize Firebase di project
firebase init

# Pilih services: Authentication, Firestore
```

### 3. Install Dependencies
```bash
# Clone repository
git clone https://github.com/AndikaBN/cafe_well_doco.git
cd cafe_well_doco

# Install dependencies
flutter pub get
```

### 4. Konfigurasi Firebase
- Buat project di [Firebase Console](https://console.firebase.google.com)
- Download `google-services.json` (Android) dan `GoogleService-Info.plist` (iOS)
- Letakkan di folder yang sesuai

### 5. Deploy Firestore Rules
```bash
firebase deploy --only firestore:rules
```

### 6. Run Aplikasi
```bash
# Debug mode
flutter run

# Release mode (APK)
flutter build apk --release
```

---

## 🎨 Tema & UI Design

### Color Palette (Coffee Theme)
```dart
class AppColors {
  // Dark Brown (Background utama)
  static const Color darkBrown = Color(0xFF1A1410);
  
  // Coffee Cream (Primary color)
  static const Color coffeeCream = Color(0xFF8B6F47);
  
  // Latte (Secondary/Accent)
  static const Color latte = Color(0xFFD4A574);
}
```

---

## 📊 Database Structure (Firestore Collections)

### Collection: `users`
```javascript
{
  "id": "auto-generated-uid",
  "displayName": "string",
  "email": "string",
  "role": "admin" | "karyawan",
  "approved": boolean,
  "createdAt": timestamp
}
```

### Collection: `products`
```javascript
{
  "id": "auto-generated-id",
  "name": "string",
  "stock": number,
  "unit": "string",
  "updatedAt": timestamp
}
```

### Collection: `stock_in`
```javascript
{
  "id": "auto-generated-id",
  "productId": "string",
  "qty": number,
  "adminId": "string",
  "timestamp": timestamp,
  "note": "string"
}
```

### Collection: `stock_out`
```javascript
{
  "id": "auto-generated-id",
  "productId": "string",
  "qty": number,
  "userId": "string",
  "timestamp": timestamp,
  "note": "string"
}
```

### Collection: `requests`
```javascript
{
  "id": "auto-generated-id",
  "userId": "string",
  "productId": "string",
  "qty": number,
  "status": "queued" | "done" | "rejected",
  "createdAt": timestamp,
  "processedAt": timestamp | null,
  "note": "string",
  "rejectReason": "string" | null
}
```

### Collection: `invites`
```javascript
{
  "code": "string",
  "createdByAdminId": "string",
  "role": "admin" | "karyawan",
  "createdAt": timestamp,
  "validUntil": timestamp | null
}
```

---

## 📝 Catatan Penting

### Atomic Operations dengan Transaction
Semua operasi yang melibatkan multiple documents menggunakan Firestore Transaction untuk menjamin:
- **Atomicity**: Operasi sukses semua atau gagal semua
- **Consistency**: Data tetap konsisten
- **Isolation**: Transaksi tidak saling mengganggu
- **Durability**: Data yang sudah tersimpan tidak hilang

### Client-Side Sorting
Untuk menghindari composite index Firebase, sorting dilakukan di client-side:
```dart
users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
```

### Firebase Free Tier Limitations
- **Firestore**: 1GB storage, 50K reads/day, 20K writes/day
- **Authentication**: Unlimited users
- **Hosting**: 10GB storage, 360MB/day bandwidth

---

## 🤝 Kontributor

- **Developer**: Andika Bintang Nugroho
- **Framework**: Flutter Team
- **Backend**: Firebase Team

---

## 📄 License

Project ini dibuat untuk keperluan skripsi dan pembelajaran.

---

## 📧 Kontak

Untuk pertanyaan atau support:
- GitHub: [@AndikaBN](https://github.com/AndikaBN)
- Repository: [cafe_well_doco](https://github.com/AndikaBN/cafe_well_doco)

---

## 🎓 Kesimpulan

Aplikasi Coffee Well Doco Inventory Management System ini merupakan solusi lengkap untuk manajemen inventori berbasis mobile dengan fitur:

✅ **Keamanan**: Firebase Authentication + Role-based security rules  
✅ **Real-time**: Data sinkron real-time dengan Firestore  
✅ **Atomic Operations**: Transaction untuk operasi critical  
✅ **User-friendly**: UI/UX dark coffee theme yang modern  
✅ **Reporting**: Export laporan ke PDF  
✅ **Scalable**: Arsitektur clean code dengan separation of concerns  

Cocok untuk skripsi dengan topik:
- Sistem Informasi Manajemen Inventori
- Aplikasi Mobile berbasis Cloud
- Implementasi Firebase di Flutter
- Real-time Database Application
- Role-based Access Control System

**Selamat mengerjakan skripsi! 🎓☕**
