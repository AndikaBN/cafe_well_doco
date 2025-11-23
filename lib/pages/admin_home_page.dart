import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cafe_well_doco/services/auth_service.dart';
import 'package:cafe_well_doco/models/user_model.dart';
import 'package:cafe_well_doco/pages/splash_page.dart';
import 'package:cafe_well_doco/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:cafe_well_doco/pages/product_management_page.dart';
import 'package:cafe_well_doco/pages/user_approval_page.dart';
import 'package:cafe_well_doco/pages/invites_page.dart';
import 'package:cafe_well_doco/pages/requests_management_page.dart';
import 'package:cafe_well_doco/pages/stock_in_page.dart';
import 'package:cafe_well_doco/pages/sample_data_seeder_page.dart';
import 'package:cafe_well_doco/pages/reports_page.dart';

/// Halaman utama untuk Admin
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final _authService = AuthService();
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final user = await _authService.getUserData(uid);
      if (mounted) {
        setState(() => _currentUser = user);
      }
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SplashPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              Provider.of<ThemeProvider>(context).isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
            tooltip: 'Ganti Tema',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Keluar',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(
                          Icons.admin_panel_settings,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selamat datang,',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentUser?.displayName ?? 'Admin',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Administrator',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Menu Grid
              Text(
                'Menu Utama',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  _buildMenuCard(
                    context,
                    icon: Icons.inventory_2,
                    title: 'Kelola Produk',
                    subtitle: 'Tambah, edit, hapus produk',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProductManagementPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context,
                    icon: Icons.add_box,
                    title: 'Tambah Stok',
                    subtitle: 'Input stok masuk',
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StockInPage()),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context,
                    icon: Icons.assignment,
                    title: 'Kelola Request',
                    subtitle: 'Proses permintaan barang',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RequestsManagementPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context,
                    icon: Icons.people,
                    title: 'Approval User',
                    subtitle: 'Setujui pendaftaran',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UserApprovalPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context,
                    icon: Icons.card_giftcard,
                    title: 'Kode Undangan',
                    subtitle: 'Buat kode untuk karyawan',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InvitesPage()),
                      );
                    },
                  ),
                  // _buildMenuCard(
                  //   context,
                  //   icon: Icons.upload_file,
                  //   title: 'Sample Data',
                  //   subtitle: 'Populate data produk',
                  //   color: Colors.purple,
                  //   onTap: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (_) => const SampleDataSeederPage(),
                  //       ),
                  //     );
                  //   },
                  // ),
                  _buildMenuCard(
                    context,
                    icon: Icons.assessment,
                    title: 'Laporan',
                    subtitle: 'Laporan pengambilan barang',
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReportsPage()),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
