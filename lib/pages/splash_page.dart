import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cafe_well_doco/pages/login_page.dart';
import 'package:cafe_well_doco/pages/admin_home_page.dart';
import 'package:cafe_well_doco/pages/karyawan_home_page.dart';
import 'package:cafe_well_doco/models/user_model.dart';

/// Splash screen untuk check auth state dan redirect otomatis
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Delay sedikit untuk splash effect
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final currentUser = FirebaseAuth.instance.currentUser;

    // Jika tidak ada user login, ke login page
    if (currentUser == null) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }

    // Jika ada user login, ambil data dari Firestore
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!mounted) return;

      if (!userDoc.exists) {
        // User document tidak ada, logout dan ke login
        await FirebaseAuth.instance.signOut();
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
        return;
      }

      final userData = UserModel.fromFirestore(userDoc);

      // Check approval status
      if (!userData.approved) {
        // User belum di-approve, logout dan tampilkan pesan
        await FirebaseAuth.instance.signOut();
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));

        // Tampilkan snackbar after navigation
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Akun Anda masih menunggu persetujuan admin'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        });
        return;
      }

      // User approved, redirect berdasarkan role
      if (userData.role == 'admin') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminHomePage()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const KaryawanHomePage()),
        );
      }
    } catch (e) {
      // Error saat fetch data, logout dan ke login
      if (mounted) {
        await FirebaseAuth.instance.signOut();
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1410), Color(0xFF2D1F17)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF3D2817),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B6F47).withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Image.asset(
                  "assets/images/logo-coffe.png",
                  width: 80,
                  height: 80,
                  fit: BoxFit.fill,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Coffee Well Do & co',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD4A574),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inventory Management System',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF8B6F47),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 40),
              // Loading indicator
              CircularProgressIndicator(
                color: const Color(0xFF8B6F47),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
