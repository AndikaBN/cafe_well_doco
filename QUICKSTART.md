# Quick Start Guide - CoffeWellDoco Inventory

Panduan cepat untuk memulai proyek dalam 10 menit!

## 🚀 Langkah Cepat

### 1. Install Dependencies (1 menit)
```bash
cd cafe_well_doco
flutter pub get
```

### 2. Setup Firebase (3 menit)

**A. Buat Project di Firebase Console**
- Buka https://console.firebase.google.com/
- Klik "Add project"
- Nama: `coffe-well-doco`
- **Pilih Spark Plan (Free)**

**B. Enable Services**
1. **Authentication**: Enable Email/Password
2. **Firestore**: Create database (production mode, asia-southeast1)

**C. Configure Flutter**
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure
flutterfire configure
```

### 3. Deploy Rules (1 menit)
```bash
firebase login
firebase init firestore  # Pilih existing project, gunakan firestore.rules
firebase deploy --only firestore:rules
```

### 4. Buat Admin Pertama (2 menit)

**Via Firebase Console:**
1. Authentication → Add user
   - Email: `admin@test.com`
   - Password: `admin123` (atau lebih kuat)
   - Copy User UID
   
2. Firestore → Create collection `users`
   - Document ID: [paste User UID]
   - Fields:
     ```
     displayName: "Admin" (string)
     email: "admin@test.com" (string)
     role: "admin" (string)
     approved: true (boolean)
     createdAt: [timestamp sekarang]
     ```

### 5. Jalankan App (1 menit)
```bash
flutter run
```

### 6. Login & Seed Data (2 menit)
1. Login dengan admin@test.com
2. Dashboard Admin → **Sample Data**
3. Klik "Mulai Seed Data"
4. Tunggu sampai selesai (15 produk)

## ✅ Selesai!

Sekarang Anda bisa:
- ✅ Kelola produk
- ✅ Tambah stok
- ✅ Buat kode undangan
- ✅ Register karyawan baru
- ✅ Approve user
- ✅ Request & proses barang

## 📱 Test Flow

### Test 1: Register Karyawan
1. Logout dari admin
2. Klik "Daftar Sekarang"
3. Isi form (tanpa kode undangan)
4. Login kembali sebagai admin
5. Approval User → Setujui
6. Login sebagai karyawan → Berhasil!

### Test 2: Request Barang
1. Login sebagai karyawan
2. Request Barang → Pilih produk
3. Masukkan jumlah
4. Kirim → Langsung selesai (OPSI A)

### Test 3: Admin Review
1. Login sebagai admin
2. Kelola Request → Lihat semua request
3. Stok otomatis berkurang

## 🔧 Troubleshooting Cepat

**Error: Permission denied**
→ Deploy ulang rules: `firebase deploy --only firestore:rules`

**Error: Akun menunggu approval**
→ Admin perlu approve di menu "Approval User"

**Tidak bisa login admin**
→ Cek Firestore: `users/{uid}` harus ada dengan `approved: true`

## 📚 Dokumentasi Lengkap

Lihat `README.md` untuk dokumentasi detail.

---
Happy coding! ☕
