# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2025-11-19

### 🎉 Initial Release

#### Features

**Authentication & Authorization**
- ✅ Email/Password authentication dengan Firebase Auth
- ✅ Role-based access control (Admin & Karyawan)
- ✅ User approval flow (admin must approve new registrations)
- ✅ Invite code system untuk registrasi karyawan
- ✅ Login validation dengan approval check

**Admin Features**
- ✅ Dashboard dengan overview
- ✅ Product management (CRUD operations)
- ✅ Stock-in management dengan log
- ✅ Request management (view & process)
- ✅ User approval system
- ✅ Invite code generation & management
- ✅ Sample data seeder untuk testing

**Karyawan Features**
- ✅ Dashboard dengan product list
- ✅ Create request untuk pengambilan barang
- ✅ View request history dengan status
- ✅ Real-time stock availability view

**Technical Implementation**
- ✅ Firestore Transactions untuk atomic operations
- ✅ Client-side processing (Firebase free-tier compatible)
- ✅ Security rules dengan role-based access
- ✅ Real-time data updates dengan StreamBuilder
- ✅ Proper error handling & user feedback

#### Data Models
- `users` - User profiles dengan role & approval
- `products` - Inventory products
- `stock_in` - Stock addition logs
- `stock_out` - Stock reduction logs
- `requests` - Barang requests dari karyawan
- `invites` - Invitation codes

#### Configuration
- Firestore Security Rules
- Firebase configuration untuk multiple platforms
- Complete documentation (README, QUICKSTART, ARCHITECTURE)

### 📝 Notes

**Processing Modes:**
- **OPSI A (Default):** Direct processing dengan automatic stock reduction
- **OPSI B (Manual):** Queued processing, admin reviews & processes requests

**Firebase Free Tier:**
- Semua fitur berjalan di Spark Plan (free)
- Tidak menggunakan Cloud Functions
- Client-side transactions untuk atomicity
- Optimized untuk usage quota

### 🔄 Trade-offs

**Client-Side Processing:**
- ✅ No server costs
- ✅ Simple deployment
- ❌ No guaranteed FIFO untuk concurrent requests (OPSI A)
- ❌ No background jobs

**Upgrade Path:**
Untuk fitur advanced (auto-processing FIFO, notifications, etc), perlu upgrade ke Blaze Plan + Cloud Functions.

### 📚 Documentation
- `README.md` - Complete setup & usage guide
- `QUICKSTART.md` - 10-minute quick start
- `ARCHITECTURE.md` - Technical documentation
- `CHANGELOG.md` - This file

---

## Future Enhancements (Roadmap)

### v1.1.0 (Planned)
- [ ] Export reports (PDF/Excel)
- [ ] Advanced filtering & search
- [ ] Stock alerts (low stock notifications)
- [ ] Bulk operations
- [ ] User profile editing

### v1.2.0 (Planned)
- [ ] Dashboard analytics & charts
- [ ] Stock forecast
- [ ] Multi-language support
- [ ] Dark mode

### v2.0.0 (Requires Blaze Plan)
- [ ] Cloud Functions untuk background processing
- [ ] Email notifications
- [ ] Push notifications (FCM)
- [ ] Scheduled jobs
- [ ] Admin SDK integration untuk direct user creation

---

**Project:** CoffeWellDoco Inventory System  
**License:** MIT  
**Platform:** Flutter + Firebase  
**Firebase Plan:** Spark (Free Tier)
