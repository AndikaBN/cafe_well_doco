# Dokumentasi Logika Kode - Coffee Well Doco Inventory System

Dokumen ini berisi penjelasan detail tentang logika kode untuk 6 fitur utama aplikasi.

---

## 1. REGISTER (Registrasi User Baru)

### File: `lib/pages/register_page.dart`

### Fungsi Register
```dart
Future<void> _register() async {
  // 1. Validasi form
  if (!_formKey.currentState!.validate()) return;
  
  // 2. Validasi checkbox persetujuan
  if (!_agreeTerms) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Anda harus menyetujui syarat dan ketentuan')),
    );
    return;
  }

  setState(() => _loading = true);

  // 3. Panggil AuthService untuk registrasi
  final result = await _authService.registerWithEmail(
    email: _email.text.trim(),
    password: _password.text.trim(),
    displayName: _fullName.text.trim(),
    inviteCode: _inviteCode.text.trim().isEmpty ? null : _inviteCode.text.trim(),
  );

  setState(() => _loading = false);

  // 4. Handle hasil registrasi
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

### File: `lib/services/auth_service.dart`

### Service Logic Register
```dart
Future<Map<String, dynamic>> registerWithEmail({
  required String email,
  required String password,
  required String displayName,
  String? inviteCode,
}) async {
  try {
    // STEP 1: Validasi invite code (opsional)
    String role = 'karyawan'; // Default role
    
    if (inviteCode != null && inviteCode.isNotEmpty) {
      // Cek apakah kode undangan valid
      final inviteDoc = await _firestore
          .collection('invites')
          .doc(inviteCode)
          .get();
      
      if (!inviteDoc.exists) {
        return {
          'success': false,
          'message': 'Kode undangan tidak valid'
        };
      }
      
      final inviteData = inviteDoc.data()!;
      final validUntil = inviteData['validUntil'] as Timestamp?;
      
      // Cek apakah kode sudah kadaluarsa
      if (validUntil != null && validUntil.toDate().isBefore(DateTime.now())) {
        return {
          'success': false,
          'message': 'Kode undangan sudah kadaluarsa'
        };
      }
      
      // Ambil role dari invite code (bisa admin atau karyawan)
      role = inviteData['role'] ?? 'karyawan';
    }

    // STEP 2: Buat akun di Firebase Authentication
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // STEP 3: Update display name di Firebase Auth
    await credential.user?.updateDisplayName(displayName);

    // STEP 4: Buat dokumen user di Firestore
    await _firestore.collection('users').doc(credential.user!.uid).set({
      'displayName': displayName,
      'email': email,
      'role': role,
      'approved': false, // Default: menunggu approval admin
      'createdAt': FieldValue.serverTimestamp(),
    });

    return {
      'success': true,
      'message': 'Registrasi berhasil'
    };
  } catch (e) {
    return {
      'success': false,
      'message': 'Terjadi kesalahan: $e'
    };
  }
}
```

### Penjelasan Alur Register:
1. **Validasi Form**: Cek apakah semua field required sudah diisi dengan benar
2. **Validasi Checkbox**: User harus setuju dengan syarat dan ketentuan
3. **Validasi Invite Code** (opsional): 
   - Jika diisi, cek apakah kode valid dan belum expired
   - Role ditentukan dari invite code (admin/karyawan)
   - Jika tidak diisi, default role = karyawan
4. **Create Auth Account**: Buat akun di Firebase Authentication
5. **Create Firestore Document**: Buat dokumen user dengan `approved: false`
6. **User harus menunggu admin approve** sebelum bisa login

---

## 2. LOGIN (Masuk ke Aplikasi)

### File: `lib/pages/login_page.dart`

### Fungsi Login
```dart
Future<void> _login() async {
  // 1. Validasi form
  if (!_formKey.currentState!.validate()) return;

  setState(() => _loading = true);

  // 2. Panggil AuthService untuk sign in
  final result = await _authService.signInWithEmail(
    email: _email.text.trim(),
    password: _password.text.trim(),
  );

  setState(() => _loading = false);

  if (result['success']) {
    final user = result['user'] as UserModel;

    // 3. Cek apakah user sudah diapprove admin
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

    // 4. Simpan credentials jika "Remember Me" aktif
    if (_rememberMe) {
      await _saveCredentials();
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
    }

    // 5. Redirect ke halaman sesuai role
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

### Fungsi Remember Me
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

### File: `lib/services/auth_service.dart`

### Service Logic Login
```dart
Future<Map<String, dynamic>> signInWithEmail({
  required String email,
  required String password,
}) async {
  try {
    // STEP 1: Login menggunakan Firebase Authentication
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // STEP 2: Ambil data user dari Firestore
    final userDoc = await _firestore
        .collection('users')
        .doc(credential.user!.uid)
        .get();
    
    if (!userDoc.exists) {
      await _auth.signOut();
      return {
        'success': false,
        'message': 'Data pengguna tidak ditemukan'
      };
    }

    final user = UserModel.fromFirestore(userDoc);

    // STEP 3: Validasi status approval
    if (!user.approved) {
      return {
        'success': false,
        'message': 'Akun Anda menunggu persetujuan admin'
      };
    }

    return {
      'success': true,
      'user': user
    };
  } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found' || e.code == 'wrong-password') {
      return {
        'success': false,
        'message': 'Email atau password salah'
      };
    }
    return {
      'success': false,
      'message': 'Error: ${e.message}'
    };
  } catch (e) {
    return {
      'success': false,
      'message': 'Terjadi kesalahan: $e'
    };
  }
}
```

### File: `lib/pages/splash_page.dart`

### Auto-Login Logic
```dart
Future<void> _checkAuthState() async {
  await Future.delayed(const Duration(seconds: 2));

  // STEP 1: Cek apakah user sudah login
  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) {
    // Belum login -> redirect ke login page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
    return;
  }

  // STEP 2: Ambil data user dari Firestore
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

  // STEP 3: Redirect berdasarkan role
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

### Penjelasan Alur Login:
1. **Validasi Form**: Cek email dan password sudah diisi
2. **Firebase Authentication**: Login menggunakan email/password
3. **Ambil Data Firestore**: Ambil informasi user (role, approved status)
4. **Cek Approval Status**: Jika `approved: false`, login ditolak
5. **Remember Me**: Simpan credentials di SharedPreferences jika aktif
6. **Redirect by Role**: Admin ke AdminHomePage, Karyawan ke KaryawanHomePage
7. **Auto-Login**: Di splash screen, cek Firebase Auth state dan redirect otomatis

---

## 3. BARANG MASUK (Stock In)

### File: `lib/pages/stock_in_page.dart`

### Fungsi Submit Stock In
```dart
Future<void> _submitStockIn() async {
  // 1. Validasi form dan produk sudah dipilih
  if (!_formKey.currentState!.validate() || _selectedProduct == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lengkapi semua field')),
    );
    return;
  }

  setState(() => _loading = true);

  final qty = int.parse(_qtyController.text);
  final adminId = FirebaseAuth.instance.currentUser!.uid;

  // 2. Panggil FirestoreService untuk tambah stok
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

### File: `lib/services/firestore_service.dart`

### Service Logic Add Stock In (dengan Transaction)
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
      
      // STEP 1: Ambil document produk
      final productRef = _firestore.collection('products').doc(productId);
      final productDoc = await transaction.get(productRef);

      if (!productDoc.exists) {
        throw Exception('Produk tidak ditemukan');
      }

      // STEP 2: Hitung stok baru
      final currentStock = productDoc.data()!['stock'] as int;
      final newStock = currentStock + qty;

      // STEP 3: Update stok produk
      transaction.update(productRef, {
        'stock': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // STEP 4: Buat log stock_in untuk tracking
      final stockInRef = _firestore.collection('stock_in').doc();
      transaction.set(stockInRef, {
        'productId': productId,
        'qty': qty,
        'adminId': adminId,
        'timestamp': FieldValue.serverTimestamp(),
        'note': note ?? '',
      });

      return {
        'success': true,
        'message': 'Stok berhasil ditambahkan'
      };
    });
  } catch (e) {
    return {
      'success': false,
      'message': 'Gagal menambah stok: ${e.toString()}'
    };
  }
}
```

### Penjelasan Alur Barang Masuk:
1. **Validasi**: Pastikan produk dipilih dan qty valid
2. **Firestore Transaction**: Gunakan transaction untuk atomic operation
   - **Read**: Ambil data produk saat ini
   - **Calculate**: Hitung stok baru = stok lama + qty masuk
   - **Update**: Update stok produk
   - **Create Log**: Buat dokumen di collection `stock_in` untuk tracking
3. **Atomic Operation**: Semua step sukses atau gagal bersamaan (tidak ada inconsistency)
4. **Tracking**: Setiap penambahan stok tercatat dengan timestamp, adminId, dan note

**Mengapa pakai Transaction?**
- Mencegah race condition (2 admin tambah stok bersamaan)
- Menjamin data consistency
- Jika salah satu operasi gagal, semua rollback

---

## 4. BARANG KELUAR (Request Barang oleh Karyawan)

### File: `lib/pages/create_request_page.dart`

### Fungsi Submit Request
```dart
Future<void> _submitRequest() async {
  // 1. Validasi form dan produk sudah dipilih
  if (!_formKey.currentState!.validate() || _selectedProduct == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lengkapi semua field')),
    );
    return;
  }

  // 2. Validasi stok tersedia
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

  // 3. OPSI A: Direct processing (langsung kurangi stok)
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

### File: `lib/services/firestore_service.dart`

### Service Logic - Direct Processing (dengan Transaction)
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
      
      // STEP 1: Ambil document produk
      final productRef = _firestore.collection('products').doc(productId);
      final productSnapshot = await transaction.get(productRef);

      if (!productSnapshot.exists) {
        throw Exception('Produk tidak ditemukan');
      }

      final currentStock = productSnapshot.data()!['stock'] as int;

      // STEP 2: Validasi stok mencukupi
      if (currentStock < qty) {
        throw Exception(
          'Stok tidak mencukupi. Stok tersedia: $currentStock'
        );
      }

      final newStock = currentStock - qty;

      // STEP 3: Update stok produk (mengurangi)
      transaction.update(productRef, {
        'stock': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // STEP 4: Buat log stock_out untuk tracking pengambilan
      final stockOutRef = _firestore.collection('stock_out').doc();
      transaction.set(stockOutRef, {
        'productId': productId,
        'qty': qty,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'note': note ?? '',
      });

      // STEP 5: Buat request dengan status 'done' (langsung selesai)
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

### Penjelasan Alur Barang Keluar:
1. **Validasi**: Pastikan produk dipilih dan qty valid
2. **Cek Stok**: Validasi stok mencukupi untuk request
3. **Firestore Transaction**: Atomic operation untuk 3 operasi sekaligus:
   - **Read & Validate**: Ambil stok dan cek mencukupi
   - **Update Product**: Kurangi stok produk
   - **Create Stock Out Log**: Buat log pengambilan barang
   - **Create Request**: Buat request dengan status 'done'
4. **Direct Processing**: Tidak perlu approval admin, langsung proses
5. **Tracking**: Setiap pengambilan tercatat di `stock_out` dan `requests`

**Mengapa pakai Transaction?**
- Mencegah over-withdrawal (2 karyawan request bersamaan melebihi stok)
- Menjamin stok tidak negatif
- Jika stok tidak cukup, semua operasi dibatalkan
- Consistency antara product.stock, stock_out, dan requests

---

## 5. LAPORAN (Reports dengan PDF Export)

### File: `lib/pages/reports_page.dart`

### Fungsi Load Data
```dart
Future<void> _loadData() async {
  setState(() => _loading = true);

  // STEP 1: Ambil semua stock out
  final stream = _firestoreService.getStockOutStream();
  final allData = await stream.first;

  // STEP 2: Normalisasi tanggal untuk filter yang tepat
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

  // STEP 3: Filter berdasarkan tanggal
  final filtered = allData.where((item) {
    return !item.timestamp.isBefore(startOfDay) &&
        !item.timestamp.isAfter(endOfDay);
  }).toList();

  // STEP 4: Sort by timestamp descending (terbaru dulu)
  filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

  setState(() {
    _filteredData = filtered;
    _loading = false;
  });
}
```

### Fungsi Generate PDF
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

    // STEP 1: Ambil data lengkap untuk setiap stock out
    for (var stockOut in _filteredData!) {
      final user = await _firestoreService.getUserById(stockOut.userId);
      final product = await _firestoreService.getProduct(stockOut.productId);

      if (user != null && product != null) {
        // STEP 2: Hitung stok sebelum diambil (untuk kolom Jumlah Masuk)
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

    // STEP 3: Build PDF dengan 7 kolom
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
                pw.SizedBox(height: 4),
                pw.Text(
                  'Periode: ${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Divider(thickness: 2),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Tabel Data (7 kolom)
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.5), // Karyawan
              1: const pw.FlexColumnWidth(1.5), // Tanggal
              2: const pw.FlexColumnWidth(1.8), // Bahan Masuk
              3: const pw.FlexColumnWidth(1.3), // Jumlah Masuk
              4: const pw.FlexColumnWidth(1.8), // Bahan Keluar
              5: const pw.FlexColumnWidth(1.3), // Jumlah Keluar
              6: const pw.FlexColumnWidth(1.3), // Stok
            },
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

          pw.SizedBox(height: 20),

          // Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Text('Total Transaksi: ${reportData.length}'),
          ),
        ],
      ),
    );

    // STEP 4: Close loading dialog
    if (mounted) Navigator.of(context).pop();

    // STEP 5: Tampilkan preview PDF dan opsi print/save
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

pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: isHeader ? 10 : 9,
        fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
}
```

### File: `lib/services/firestore_service.dart`

### Fungsi Backfill Stock Out
```dart
Future<Map<String, dynamic>> backfillStockOut() async {
  try {
    int created = 0;
    int skipped = 0;

    // STEP 1: Ambil semua request dengan status 'done'
    final requestsSnapshot = await _firestore
        .collection('requests')
        .where('status', isEqualTo: 'done')
        .get();

    // STEP 2: Ambil semua stock_out yang sudah ada
    final stockOutSnapshot = await _firestore
        .collection('stock_out')
        .get();
    
    // STEP 3: Buat Set untuk cek duplikat
    final existingStockOuts = <String>{};
    for (var doc in stockOutSnapshot.docs) {
      final data = doc.data();
      final key = '${data['userId']}_${data['productId']}_${(data['timestamp'] as Timestamp).millisecondsSinceEpoch}';
      existingStockOuts.add(key);
    }

    // STEP 4: Proses setiap request
    for (var requestDoc in requestsSnapshot.docs) {
      final data = requestDoc.data();
      final userId = data['userId'] as String;
      final productId = data['productId'] as String;
      final qty = data['qty'] as int;
      final note = data['note'] as String? ?? '';
      final processedAt = data['processedAt'] as Timestamp?;

      if (processedAt == null) {
        skipped++;
        continue;
      }

      // STEP 5: Cek apakah sudah ada stock_out untuk request ini
      final key = '${userId}_${productId}_${processedAt.millisecondsSinceEpoch}';
      
      if (existingStockOuts.contains(key)) {
        skipped++;
        continue;
      }

      // STEP 6: Buat stock_out baru
      await _firestore.collection('stock_out').add({
        'productId': productId,
        'qty': qty,
        'userId': userId,
        'timestamp': processedAt,
        'note': note,
      });

      created++;
    }

    return {
      'success': true,
      'message': 'Backfill selesai. Dibuat: $created, Dilewati: $skipped',
      'created': created,
      'skipped': skipped,
    };
  } catch (e) {
    return {
      'success': false,
      'message': 'Gagal backfill: ${e.toString()}',
    };
  }
}
```

### Penjelasan Alur Laporan:
1. **Load Data**:
   - Query collection `stock_out`
   - Filter berdasarkan range tanggal
   - Sort descending (terbaru dulu)
   
2. **Generate PDF**:
   - Untuk setiap stock_out, join dengan user dan product
   - Hitung "Jumlah Masuk" = stok saat ini + qty yang diambil
   - Format tanggal Indonesia (dd/MM/yyyy HH:mm)
   - Build tabel PDF dengan 7 kolom:
     1. Karyawan (displayName)
     2. Tanggal (timestamp pengambilan)
     3. Bahan Masuk (product.updatedAt)
     4. Jumlah Masuk (calculated)
     5. Bahan Keluar (product.name)
     6. Jumlah Keluar (qty)
     7. Stok (stok saat ini)
   
3. **Backfill**: 
   - Regenerate stock_out dari request lama
   - Cek duplikat sebelum create
   - Useful untuk sinkronisasi data

**Struktur PDF**:
- Header dengan judul dan periode
- Tabel 7 kolom dengan border
- Summary total transaksi
- Format A4 landscape
- Support print dan save to file

---

## 6. APPROVAL USER (Persetujuan User Baru)

### File: `lib/pages/user_approval_page.dart`

### Fungsi Approve/Reject User
```dart
Future<void> _approveUser(String userId, bool approve) async {
  try {
    // STEP 1: Update field 'approved' di Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'approved': approve});

    // STEP 2: Tampilkan notifikasi sukses
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

### Widget untuk Menampilkan Daftar User Pending
```dart
Widget _buildUserList() {
  return StreamBuilder<List<UserModel>>(
    // STEP 1: Stream user yang belum approved
    stream: _firestoreService.getUsersStream(approved: false),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }

      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      final users = snapshot.data!;

      if (users.isEmpty) {
        return const Center(
          child: Text('Belum ada user yang menunggu approval'),
        );
      }

      // STEP 2: Build list tile untuk setiap user
      return ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  user.displayName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(user.displayName),
              subtitle: Text(
                '${user.email}\nRole: ${user.role}\nTerdaftar: ${DateFormat('dd/MM/yyyy HH:mm').format(user.createdAt)}',
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tombol Approve
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () => _approveUser(user.id, true),
                    tooltip: 'Setujui',
                  ),
                  // Tombol Reject
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => _showRejectDialog(user),
                    tooltip: 'Tolak',
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
```

### File: `lib/services/firestore_service.dart`

### Service untuk Get Users Stream
```dart
Stream<List<UserModel>> getUsersStream({bool? approved}) {
  Query query = _firestore.collection('users');

  // STEP 1: Filter berdasarkan approved status
  if (approved != null) {
    query = query.where('approved', isEqualTo: approved);
  }

  // STEP 2: Listen to snapshots (real-time)
  return query.snapshots().map((snapshot) {
    final users = snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .toList();

    // STEP 3: Sorting di client-side (descending by createdAt)
    // Tidak pakai orderBy di query untuk avoid composite index
    users.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return users;
  });
}
```

### Fungsi Reject dengan Dialog
```dart
Future<void> _showRejectDialog(UserModel user) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Tolak User'),
      content: Text(
        'Anda yakin ingin menolak user ${user.displayName}?\n\n'
        'User akan dihapus dari sistem dan tidak bisa login.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Tolak'),
        ),
      ],
    ),
  );

  if (confirm == true) {
    try {
      // STEP 1: Hapus user dari Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .delete();

      // STEP 2: Hapus user dari Firebase Authentication
      // Note: Ini tidak bisa dilakukan dari client-side
      // Harus pakai Cloud Functions atau Admin SDK
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User berhasil ditolak dan dihapus'),
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
}
```

### Penjelasan Alur Approval User:
1. **Stream Real-time**:
   - Query users dengan `approved: false`
   - Listen to Firestore snapshots
   - UI update otomatis saat ada perubahan
   
2. **Approve**:
   - Update field `approved: true`
   - User bisa login setelah di-approve
   - StreamBuilder otomatis remove dari list pending
   
3. **Reject**:
   - Tampilkan confirmation dialog
   - Hapus dokumen user dari Firestore
   - Ideally juga hapus dari Firebase Auth (butuh Cloud Functions)
   
4. **Client-side Sorting**:
   - Tidak pakai `orderBy()` di query
   - Sorting manual di client setelah data diterima
   - Menghindari composite index requirement di Firebase

**Real-time Updates**:
- Pakai StreamBuilder untuk auto-refresh
- Tidak perlu manual refresh
- Saat admin approve/reject, UI langsung update
- Multiple admin bisa approve bersamaan tanpa conflict

---

## Ringkasan Konsep Penting

### 1. Firestore Transactions
- Digunakan untuk operasi yang melibatkan multiple documents
- Menjamin atomicity (all or nothing)
- Mencegah race conditions
- Dipakai di: Stock In, Stock Out/Request

### 2. Real-time dengan Streams
- StreamBuilder untuk listen perubahan data
- Auto-refresh UI tanpa manual reload
- Dipakai di: User Approval, Product List, Request List

### 3. Client-side Sorting
- Hindari composite index Firebase
- Sort data setelah query
- Lebih flexible dan gratis (free tier)

### 4. Security dengan Rules
- Role-based access control
- Validasi di server-side (Firestore Rules)
- Cegah unauthorized access

### 5. State Management
- setState untuk local state
- Provider untuk global state (Theme)
- Loading states untuk UX yang baik

---

**Dokumentasi ini cocok untuk:**
- Skripsi/Thesis documentation
- Code review
- Onboarding developer baru
- Technical presentation

**Last Updated**: 1 Desember 2025
