# CoffeWellDoco Inventory System

Sistem manajemen inventory untuk CoffeWellDoco yang menggunakan **Firebase Spark Plan (FREE)** dengan Firebase Authentication, Cloud Firestore, dan Hosting.

## 📋 Fitur Utama

### Autentikasi & Authorization
- ✅ Register dengan Email/Password
- ✅ Login dengan validasi approval admin
- ✅ Sistem invite code untuk registrasi karyawan
- ✅ Role-based access (Admin & Karyawan)
- ✅ Approval flow untuk user baru

### Manajemen Inventory (Admin)
- ✅ CRUD Produk
- ✅ Input stok masuk dengan log
- ✅ Kelola request karyawan
- ✅ Approval user baru
- ✅ Generate dan kelola kode undangan

### Request Barang (Karyawan)
- ✅ Request pengambilan barang
- ✅ Riwayat request dengan status
- ✅ View daftar produk tersedia
- ✅ Processing otomatis dengan Firestore Transactions

## 🚀 Setup Project

### Prasyarat
- Flutter SDK (3.9.0 atau lebih baru)
- Dart SDK
- Firebase CLI
- Akun Firebase (Spark Plan / Free Tier)

### Langkah 1: Clone & Install Dependencies

```bash
cd cafe_well_doco
flutter pub get
```

### Langkah 2: Setup Firebase Project

1. **Buat Firebase Project**
   - Buka [Firebase Console](https://console.firebase.google.com/)
   - Klik "Add project" atau "Tambahkan project"
   - Nama project: `coffe-well-doco` (atau sesuaikan)
   - Pilih **Spark Plan (Free)**
   - Tunggu hingga project selesai dibuat

2. **Enable Firebase Authentication**
   - Di Firebase Console, buka **Authentication**
   - Klik tab **Sign-in method**
   - Enable **Email/Password**
   - Klik **Save**

3. **Enable Cloud Firestore**
   - Di Firebase Console, buka **Firestore Database**
   - Klik **Create database**
   - Pilih **Start in production mode**
   - Pilih location (asia-southeast1 untuk Asia Tenggara)
   - Klik **Enable**

4. **Configure Flutter Apps**
   ```bash
   # Install FlutterFire CLI jika belum
   dart pub global activate flutterfire_cli
   
   # Configure Firebase untuk Flutter
   flutterfire configure
   ```
   
   - Pilih project Firebase yang sudah dibuat
   - Pilih platforms yang ingin didukung (iOS, Android, Web, dll)
   - File `firebase_options.dart` akan di-generate otomatis

### Langkah 3: Deploy Firestore Security Rules

```bash
# Login ke Firebase CLI (jika belum)
firebase login

# Initialize Firebase di project (jika belum)
firebase init firestore

# Pilih existing project
# Gunakan file firestore.rules yang sudah ada

# Deploy rules
firebase deploy --only firestore:rules
```

### Langkah 4: Buat Admin Pertama

Karena sistem ini menggunakan approval flow dan tidak ada server-side untuk create account otomatis, admin pertama harus dibuat manual:

**Opsi A: Via Firebase Console (Rekomendasi)**

1. Buka Firebase Console → Authentication
2. Klik **Add user**
3. Masukkan:
   - Email: `admin@coffewelldoco.com` (sesuaikan)
   - Password: buat password yang kuat
4. Copy **User UID** yang muncul
5. Buka Firestore Database
6. Buat collection baru: `users`
7. Buat document dengan Document ID = User UID yang di-copy
8. Tambahkan fields:
   ```
   displayName: "Admin Utama" (string)
   email: "admin@coffewelldoco.com" (string)
   role: "admin" (string)
   approved: true (boolean)
   createdAt: [pilih timestamp, set ke waktu sekarang]
   ```
9. Save document

**Opsi B: Register via App, lalu Manual Approve**

1. Jalankan app
2. Register dengan email admin
3. Buka Firestore Console
4. Edit document `users/{uid}` yang baru dibuat
5. Ubah:
   - `role`: "admin"
   - `approved`: true

### Langkah 5: Jalankan Aplikasi

```bash
# Android
flutter run

# iOS (butuh macOS)
flutter run

# Web
flutter run -d chrome
```

## 📱 Penggunaan Aplikasi

### Alur untuk Admin

1. **Login** dengan akun admin
2. **Dashboard Admin** akan muncul dengan menu:
   - **Kelola Produk**: Tambah, edit, hapus produk
   - **Tambah Stok**: Input stok masuk untuk produk
   - **Kelola Request**: Lihat dan proses request dari karyawan
   - **Approval User**: Setujui/tolak registrasi karyawan baru
   - **Kode Undangan**: Buat kode untuk registrasi karyawan

3. **Tambah Produk**
   - Klik "Kelola Produk"
   - Klik tombol "+"
   - Isi nama, stok awal, dan satuan
   - Simpan

4. **Buat Kode Undangan**
   - Klik "Kode Undangan"
   - Klik tombol "+"
   - Pilih role (biasanya "karyawan")
   - Opsional: set tanggal kadaluarsa
   - Kode akan di-generate (contoh: `ABC123`)
   - Salin dan bagikan ke calon karyawan

5. **Approve User Baru**
   - Klik "Approval User"
   - Tab "Menunggu Approval" menampilkan user pending
   - Klik menu (⋮) → Setujui atau Tolak

6. **Proses Request** (jika menggunakan OPSI B - manual processing)
   - Klik "Kelola Request"
   - Pilih status "Menunggu"
   - Expand request yang ingin diproses
   - Klik "Proses" (stok akan dikurangi otomatis via transaction)
   - Atau "Tolak" dengan alasan

### Alur untuk Karyawan

1. **Register**
   - Buka aplikasi
   - Klik "Daftar Sekarang"
   - Isi form registrasi
   - **Opsional**: Masukkan kode undangan dari admin
   - Klik "Daftar"
   - Akan muncul pesan "Menunggu persetujuan admin"

2. **Tunggu Approval**
   - Hubungi admin untuk approval
   - Setelah di-approve, bisa login

3. **Login**
   - Masukkan email dan password
   - Jika belum di-approve, akan muncul error
   - Jika sudah approved, masuk ke Dashboard Karyawan

4. **Request Barang**
   - Klik "Request Barang"
   - Pilih produk dari dropdown
   - Masukkan jumlah (tidak boleh melebihi stok)
   - Tambahkan catatan (opsional)
   - Klik "Kirim Request"
   - **OPSI A**: Request langsung diproses (stok dikurangi)
   - **OPSI B**: Request masuk antrian, tunggu admin proses

5. **Lihat Riwayat**
   - Klik "Riwayat Request"
   - Lihat semua request dengan status:
     - **Menunggu**: Belum diproses admin (OPSI B)
     - **Selesai**: Request berhasil diproses
     - **Ditolak**: Request ditolak dengan alasan

## 🔧 Konfigurasi Processing Mode

Aplikasi ini mendukung 2 opsi processing request:

### OPSI A: Direct Processing (Default) ✅
Request langsung diproses saat dibuat oleh karyawan menggunakan Firestore Transaction untuk atomicity.

**Kelebihan:**
- Instant processing
- Tidak perlu intervensi admin
- Lebih efisien untuk tim kecil

**Kekurangan:**
- Tidak ada FIFO guarantee jika banyak request simultan
- Admin tidak bisa review sebelum approve

**File**: `lib/pages/create_request_page.dart`
```dart
// Baris 62-67 (OPSI A aktif)
final result = await _firestoreService.createRequestDirect(
  userId: userId,
  productId: _selectedProduct!.id,
  qty: qty,
  note: _noteController.text.trim(),
);
```

### OPSI B: Queued Processing (Manual Admin)
Request masuk antrian, admin memproses secara manual dengan urutan FIFO.

**Kelebihan:**
- Admin review sebelum approve
- FIFO guarantee jika admin memproses berurutan
- Kontrol lebih ketat

**Kekurangan:**
- Butuh manual processing oleh admin
- Lebih lambat

**Cara Aktifkan:**

Edit file `lib/pages/create_request_page.dart`:

```dart
// Comment OPSI A (baris 62-67)
// final result = await _firestoreService.createRequestDirect(
//   ...
// );

// Uncomment OPSI B (baris 72-77)
final result = await _firestoreService.createRequestQueued(
  userId: userId,
  productId: _selectedProduct!.id,
  qty: qty,
  note: _noteController.text.trim(),
);
```

## 🔐 Security Rules

Firestore Security Rules sudah dikonfigurasi untuk:

✅ User hanya bisa create profile sendiri saat register
✅ User tidak bisa ubah role atau approved status sendiri
✅ Admin bisa approve/reject user
✅ Hanya admin yang bisa CRUD products dan stock_in
✅ Karyawan yang approved bisa create request
✅ Transaction-based operations untuk atomic stock updates
✅ Semua writes di-validate di client dan server-side

File: `firestore.rules`

## 📊 Data Model

### Collection: `users`
```
{
  displayName: string
  email: string
  role: "admin" | "karyawan"
  approved: boolean
  createdAt: timestamp
}
```

### Collection: `products`
```
{
  name: string
  stock: number
  unit: string
  updatedAt: timestamp
}
```

### Collection: `stock_in`
```
{
  productId: string
  qty: number
  adminId: string
  timestamp: timestamp
  note: string
}
```

### Collection: `stock_out`
```
{
  productId: string
  qty: number
  userId: string
  timestamp: timestamp
  note: string
}
```

### Collection: `requests`
```
{
  userId: string
  productId: string
  qty: number
  status: "queued" | "processing" | "done" | "rejected"
  createdAt: timestamp
  processedAt: timestamp?
  note: string
  rejectReason: string?
}
```

### Collection: `invites`
```
{
  createdByAdminId: string
  role: string
  createdAt: timestamp
  validUntil: timestamp?
  used: boolean
  usedBy: string?
}
```

## 🧪 Testing Manual

### Test Case 1: Registrasi & Approval
1. Register user baru tanpa kode undangan
2. Coba login → Harus gagal dengan pesan "menunggu approval"
3. Login sebagai admin → approve user
4. Login sebagai user baru → Harus berhasil

### Test Case 2: Invite Code
1. Login sebagai admin
2. Buat kode undangan
3. Logout, register user baru dengan kode tersebut
4. Cek di Firestore → invite harus marked as used
5. Coba pakai kode yang sama lagi → Harus gagal

### Test Case 3: Stock Operations
1. Login sebagai admin
2. Tambah produk "Kopi Arabica" dengan stok 100 kg
3. Input stok masuk +50 kg
4. Cek di Firestore → stok harus 150 kg
5. Cek collection `stock_in` → ada log entry

### Test Case 4: Request Processing (OPSI A)
1. Login sebagai karyawan
2. Request 20 kg Kopi Arabica
3. Request langsung selesai
4. Cek Firestore → stok berkurang jadi 130 kg
5. Ada entry di `stock_out` dan `requests` (status: done)

### Test Case 5: Request Processing (OPSI B)
1. Switch ke OPSI B di kode
2. Login sebagai karyawan
3. Request 20 kg Kopi Arabica
4. Status request: "queued"
5. Login sebagai admin
6. Proses request → stok berkurang atomically
7. Status berubah jadi "done"

### Test Case 6: Stock Insufficient
1. Request jumlah melebihi stok tersedia
2. Harus gagal dengan pesan error
3. Stok tidak berubah
4. Tidak ada entry baru di `stock_out`

### Test Case 7: Concurrent Requests
1. Simulasi 2 karyawan request barang yang sama secara bersamaan
2. Total qty melebihi stok
3. Satu request harus berhasil, yang lain gagal
4. Stok final harus konsisten (tidak negatif)

## 🔍 Troubleshooting

### Error: "Akun menunggu persetujuan admin"
**Solusi**: Hubungi admin untuk approve akun Anda, atau jika Anda admin pertama, ikuti langkah "Buat Admin Pertama" di atas.

### Error: "Permission denied" di Firestore
**Solusi**: 
1. Pastikan Firestore Rules sudah di-deploy: `firebase deploy --only firestore:rules`
2. Cek apakah user sudah approved (field `approved: true`)
3. Cek role user sesuai dengan operasi yang dilakukan

### Stok tidak berkurang setelah request
**Solusi**:
1. Cek di Firestore Console apakah ada error
2. Pastikan Firestore Transactions berjalan (lihat logs)
3. Jika pakai OPSI B, pastikan admin sudah proses request

### Kode undangan tidak bisa dipakai
**Solusi**:
1. Cek apakah kode sudah dipakai (`used: true`)
2. Cek apakah sudah kadaluarsa (`validUntil` < sekarang)
3. Pastikan copy-paste kode dengan benar (case-sensitive)

## 📝 Trade-offs & Limitasi Firebase Free Tier

### ✅ Yang Bisa Dilakukan (Free Tier)
- Authentication dengan Email/Password
- Cloud Firestore (reads, writes, storage dalam limit)
- Firestore Transactions untuk atomicity
- Client-side processing
- Hosting (opsional)

### ⚠️ Limitasi Free Tier
- **No Cloud Functions**: Semua processing dilakukan di client
- **FIFO tidak terjamin secara global**: OPSI A tidak guarantee urutan jika banyak request simultan
- **No server-side admin creation**: Admin tidak bisa langsung create akun Auth user dari UI (butuh manual via console atau Cloud Functions)
- **Quota limits**: 
  - 50K reads/day
  - 20K writes/day
  - 20K deletes/day
  - 1 GB stored data
  - 10 GB/month network egress

### 🚀 Upgrade Path (jika ingin fitur premium)
Jika ingin fitur berikut, perlu upgrade ke **Blaze Plan (Pay as you go)**:

1. **Cloud Functions** untuk:
   - Auto-processing requests dengan FIFO guarantee
   - Admin create user dari UI
   - Scheduled jobs (reminder, cleanup, dll)
   - Email notifications

2. **Firebase Cloud Messaging** untuk:
   - Push notifications ke mobile

3. **Higher Quotas** untuk:
   - Scale lebih besar

**Cara Upgrade**:
```bash
# Setup Cloud Functions (setelah upgrade Blaze)
firebase init functions
```

Contoh Cloud Function untuk auto-process requests:
```javascript
// functions/index.js
exports.processRequests = functions.firestore
  .document('requests/{requestId}')
  .onCreate(async (snap, context) => {
    // Process request dengan FIFO guarantee
    // Kurangi stock via Admin SDK
  });
```

## 🤝 Kontribusi

Untuk berkontribusi:
1. Fork repository
2. Buat branch fitur: `git checkout -b fitur-baru`
3. Commit changes: `git commit -m 'Tambah fitur baru'`
4. Push ke branch: `git push origin fitur-baru`
5. Buat Pull Request

## 📄 Lisensi

MIT License - bebas digunakan untuk keperluan pribadi dan komersial.

## 📞 Support

Jika ada pertanyaan atau masalah:
1. Buka issue di GitHub repository
2. Hubungi tim development

---

**Dibuat dengan ❤️ untuk CoffeWellDoco**

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
