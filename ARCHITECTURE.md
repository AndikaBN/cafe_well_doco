# Architecture & Technical Documentation

## 📐 Arsitektur Aplikasi

### Struktur Project

```
lib/
├── main.dart                 # Entry point
├── firebase_options.dart     # Firebase config (auto-generated)
├── models/                   # Data models
│   ├── user_model.dart
│   ├── product_model.dart
│   ├── stock_model.dart      # StockIn & StockOut
│   ├── request_model.dart
│   └── invite_model.dart
├── services/                 # Business logic
│   ├── auth_service.dart     # Authentication
│   └── firestore_service.dart # Database operations
└── pages/                    # UI screens
    ├── login_page.dart
    ├── register_page.dart
    ├── admin_home_page.dart
    ├── karyawan_home_page.dart
    ├── product_management_page.dart
    ├── stock_in_page.dart
    ├── requests_management_page.dart
    ├── user_approval_page.dart
    ├── invites_page.dart
    ├── create_request_page.dart
    ├── my_requests_page.dart
    └── sample_data_seeder_page.dart
```

## 🔄 Data Flow

### 1. Authentication Flow

```
User Register
  ↓
Create Auth Account (Firebase Auth)
  ↓
Create User Document (Firestore)
  ├─ approved: false
  └─ role: "karyawan"
  ↓
[Wait Admin Approval]
  ↓
Admin Updates approved: true
  ↓
User Can Login
```

### 2. Request Flow (OPSI A - Direct)

```
Karyawan Create Request
  ↓
Firestore Transaction {
  1. Get Product Stock
  2. Validate qty <= stock
  3. Update Product: stock -= qty
  4. Create StockOut log
  5. Create Request (status: done)
}
  ↓
All or Nothing (Atomic)
```

### 3. Request Flow (OPSI B - Queued)

```
Karyawan Create Request
  ↓
Create Request (status: queued)
  ↓
Admin Views Queue (ordered by createdAt)
  ↓
Admin Clicks "Process"
  ↓
Firestore Transaction {
  1. Get Product Stock
  2. Validate qty <= stock
  3. Update Product: stock -= qty
  4. Create StockOut log
  5. Update Request (status: done)
}
```

## 🔒 Security Model

### Firestore Rules Summary

| Collection | Read | Create | Update | Delete |
|------------|------|--------|--------|--------|
| users | All auth users | Self (register) | Self (non-critical) / Admin | None |
| products | Approved users | Admin only | Admin only | Admin only |
| stock_in | Approved users | Admin only | None | None |
| stock_out | Approved users | System (transaction) | None | None |
| requests | Owner / Admin | Approved karyawan | Owner (tx) / Admin | None |
| invites | Everyone* | Admin only | Admin / System | Admin |

*Note: Di production, sebaiknya read invites dibatasi hanya untuk yang punya kode

### Role-Based Access

```dart
// Helper functions di firestore.rules
function isAdmin() {
  return role == 'admin' && approved == true
}

function isApprovedKaryawan() {
  return role == 'karyawan' && approved == true
}

function isApproved() {
  return approved == true
}
```

## ⚡ Transaction Safety

### Atomic Operations

Semua operasi yang mengubah stok menggunakan `runTransaction`:

```dart
await firestore.runTransaction((transaction) async {
  // 1. Read
  final productSnapshot = await transaction.get(productRef);
  final currentStock = productSnapshot.data()!['stock'];
  
  // 2. Validate
  if (currentStock < qty) throw Exception('Stock insufficient');
  
  // 3. Write (multiple documents)
  transaction.update(productRef, {'stock': currentStock - qty});
  transaction.set(stockOutRef, {...});
  transaction.set(requestRef, {...});
});
```

**Garantis:**
- ✅ All writes succeed or all fail
- ✅ No race conditions
- ✅ Stock never negative
- ✅ Consistent logs

### Concurrency Handling

**Skenario:** 2 requests bersamaan untuk produk yang sama

```
Initial Stock: 100

Request A: qty 80  ┐
Request B: qty 60  ┘ Simultaneous

Transaction A: Read 100 → Validate OK → Write 20
Transaction B: Read 100 → Retry (conflict) → Read 20 → Validate FAIL
                                                              ↓
                                                         Throw Error

Final Stock: 20 ✅ (consistent)
```

Firestore automatically retries transactions on conflict.

## 📊 State Management

### Pendekatan: StreamBuilder + StatefulWidget

**Mengapa tidak Provider/Bloc/Riverpod?**
- Aplikasi relatif simple
- Firebase Firestore sudah reactive (streams)
- Mengurangi complexity untuk Firebase free-tier project

**Pattern:**

```dart
StreamBuilder<List<ProductModel>>(
  stream: firestoreService.getProductsStream(),
  builder: (context, snapshot) {
    // Auto-rebuild on data change
    return ListView(...);
  },
)
```

## 🔥 Firebase Free Tier Limits

### Daily Quotas
- **Reads:** 50,000 / day
- **Writes:** 20,000 / day
- **Deletes:** 20,000 / day

### Estimasi Usage (10 karyawan, 50 requests/day)

| Operation | Count/Day | Quota Used |
|-----------|-----------|------------|
| Login | 20 | 20 reads |
| View Products | 100 | 100 reads |
| Create Request | 50 | 150 writes (product, stock_out, request) |
| View Requests | 200 | 200 reads |
| Admin Operations | 50 | ~150 reads/writes |
| **Total** | | ~520 operations/day |

**Margin:** 520 / 50,000 = **1%** of quota used
**Kesimpulan:** Sangat aman untuk 10-20 karyawan

### Optimization Tips

1. **Cache data di client**
```dart
// Bad: Query setiap render
StreamBuilder<List<Product>>(...)

// Good: Cache di state, update via stream
@override
void initState() {
  _subscription = stream.listen((data) {
    setState(() => _cachedData = data);
  });
}
```

2. **Limit query results**
```dart
query.limit(50)  // Jangan fetch semua
```

3. **Use composite queries**
```dart
// Instead of multiple queries
query.where('status', '==', 'queued')
     .orderBy('createdAt')
     .limit(20)
```

## 🚀 Performance Considerations

### Client-Side Processing

**Pros:**
- ✅ Zero server costs
- ✅ Works on free tier
- ✅ Simple architecture

**Cons:**
- ❌ Transaction retries consume client resources
- ❌ No background processing
- ❌ Limited to Firestore transaction limits (500 writes/transaction)

### Scalability Path

**Current (Free Tier):**
- Good for: 10-50 users, <1000 requests/day

**When to Upgrade (Blaze Plan + Cloud Functions):**
- >50 concurrent users
- Need background jobs
- Complex business logic
- Email/SMS notifications
- Advanced analytics

## 🧪 Testing Strategy

### Manual Testing (Current)

Lihat README.md bagian "Testing Manual"

### Unit Testing (Optional - Future)

```dart
// test/services/firestore_service_test.dart
void main() {
  group('FirestoreService', () {
    test('addProduct creates product with correct data', () async {
      // Arrange
      final service = FirestoreService();
      
      // Act
      final result = await service.addProduct(
        name: 'Test Product',
        stock: 100,
        unit: 'kg',
      );
      
      // Assert
      expect(result['success'], true);
    });
  });
}
```

### Integration Testing (Optional - Future)

```dart
// integration_test/app_test.dart
void main() {
  testWidgets('Complete flow: register, approve, request', (tester) async {
    // Test full user journey
  });
}
```

## 📝 Code Style & Conventions

### Naming
- **Files:** `snake_case.dart`
- **Classes:** `PascalCase`
- **Variables:** `camelCase`
- **Constants:** `SCREAMING_SNAKE_CASE`

### Struktur File
```dart
// 1. Imports
import 'package:flutter/material.dart';
import 'package:project/file.dart';

// 2. Class documentation
/// Documentation here

// 3. Class
class MyWidget extends StatefulWidget {
  // Constructor
  // Fields
  // Methods
}
```

### Comments
- Bahasa Indonesia untuk business logic
- English untuk technical details
- JSDoc-style untuk functions

```dart
/// Membuat request baru dengan validasi stok
/// 
/// Menggunakan Firestore transaction untuk atomic operation
/// Returns Map dengan keys: success, message, requestId?
Future<Map<String, dynamic>> createRequest(...) async {
  // Implementation
}
```

## 🔄 Migration & Deployment

### Database Migrations

Firebase Firestore tidak support traditional migrations. Strategi:

**1. Additive Changes (Recommended)**
```dart
// Add new field dengan default value
transaction.set(docRef, {
  ...existingData,
  'newField': defaultValue,
});
```

**2. Background Migration**
```dart
// One-time script via admin
void migrateAllProducts() async {
  final products = await firestore.collection('products').get();
  for (var doc in products.docs) {
    await doc.reference.update({'newField': defaultValue});
  }
}
```

### Deployment Checklist

- [ ] Update `firebase_options.dart` untuk production
- [ ] Deploy Firestore rules: `firebase deploy --only firestore:rules`
- [ ] Buat admin pertama
- [ ] Test authentication flow
- [ ] Test transaction operations
- [ ] Monitor Firestore usage di console
- [ ] Setup backup (Firestore export scheduled)

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Firestore Transactions](https://firebase.google.com/docs/firestore/manage-data/transactions)
- [Security Rules](https://firebase.google.com/docs/firestore/security/get-started)

---

**Last Updated:** November 2025
