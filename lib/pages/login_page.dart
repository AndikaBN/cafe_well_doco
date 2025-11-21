import 'dart:async';
import 'dart:ui';

import 'package:cafe_well_doco/pages/register_page.dart';
import 'package:cafe_well_doco/services/auth_service.dart';
import 'package:cafe_well_doco/pages/admin_home_page.dart';
import 'package:cafe_well_doco/pages/karyawan_home_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _authService = AuthService();
  bool _obscure = true;
  bool _loading = false;
  bool _rememberMe = false;

  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _loadRememberedCredentials();
  }

  Future<void> _loadRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('rememberMe') ?? false;

    if (rememberMe) {
      final email = prefs.getString('savedEmail') ?? '';
      final password = prefs.getString('savedPassword') ?? '';

      setState(() {
        _rememberMe = rememberMe;
        _email.text = email;
        _password.text = password;
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    if (_rememberMe) {
      await prefs.setBool('rememberMe', true);
      await prefs.setString('savedEmail', _email.text.trim());
      await prefs.setString('savedPassword', _password.text.trim());
    } else {
      await prefs.remove('rememberMe');
      await prefs.remove('savedEmail');
      await prefs.remove('savedPassword');
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _onSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final result = await _authService.signInWithEmail(
      email: _email.text.trim(),
      password: _password.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success']) {
      // Simpan credentials jika remember me dicentang
      await _saveCredentials();

      final user = result['user'];

      // Navigate berdasarkan role dengan pushReplacement (hapus history)
      if (user.role == 'admin') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminHomePage()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const KaryawanHomePage()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(result['message'])),
            ],
          ),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = 480.0;
    return Scaffold(
      backgroundColor: const Color(0xFF1A1410), // Dark brown coffee
      body: SafeArea(
        child: Stack(
          children: [
            // Coffee bean pattern background
            Positioned.fill(
              child: Opacity(
                opacity: 0.03,
                child: Image.asset(
                  "assets/images/logo-coffe.png",
                  repeat: ImageRepeat.repeat,
                  scale: 0.1,
                ),
              ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1A1410),
                    const Color(0xFF2D1F17).withOpacity(0.9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Center card
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo and title
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF3D2817),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B6F47).withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          "assets/images/logo-coffe.png",
                          width: 70,
                          height: 70,
                          fit: BoxFit.fill,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Coffee Well Do & Co',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD4A574), // Coffee cream
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
                      // Card
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D1F17),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF3D2817),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Email
                                _buildField(
                                  controller: _email,
                                  hint: 'Email',
                                  prefix: Icons.mail_outline,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty)
                                      return 'Email tidak boleh kosong';
                                    if (!RegExp(
                                      r'^[^@]+@[^@]+\.[^@]+',
                                    ).hasMatch(v))
                                      return 'Format email tidak valid';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Password
                                _buildField(
                                  controller: _password,
                                  hint: 'Password',
                                  prefix: Icons.lock_outline,
                                  obscure: _obscure,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: const Color(0xFF8B6F47),
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Password tidak boleh kosong';
                                    if (v.length < 6)
                                      return 'Minimal 6 karakter';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),
                                // Remember Me checkbox
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _rememberMe,
                                      onChanged: (value) {
                                        setState(
                                          () => _rememberMe = value ?? false,
                                        );
                                      },
                                      fillColor:
                                          MaterialStateProperty.resolveWith((
                                            states,
                                          ) {
                                            if (states.contains(
                                              MaterialState.selected,
                                            )) {
                                              return const Color(0xFF8B6F47);
                                            }
                                            return const Color(0xFF3D2817);
                                          }),
                                      checkColor: const Color(0xFF1A1410),
                                    ),
                                    Text(
                                      'Ingat saya',
                                      style: TextStyle(
                                        color: const Color(0xFFB8956A),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                // Sign in button
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _onSignIn,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF8B6F47),
                                      foregroundColor: const Color(0xFF1A1410),
                                      disabledBackgroundColor: const Color(
                                        0xFF3D2817,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 8,
                                      shadowColor: const Color(
                                        0xFF8B6F47,
                                      ).withOpacity(0.5),
                                    ),
                                    child: _loading
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: const [
                                              SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Color(0xFF1A1410),
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                              SizedBox(width: 12),
                                              Text(
                                                'Memproses...',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          )
                                        : const Text(
                                            'Masuk',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // signup hint
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Belum punya akun?',
                                      style: TextStyle(
                                        color: const Color(0xFF8B6F47),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                RegisterPage(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Daftar',
                                        style: TextStyle(
                                          color: const Color(0xFFD4A574),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Footer text
                      Text(
                        '☕ Powered by Coffee Passion',
                        style: TextStyle(
                          color: const Color(0xFF8B6F47).withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData prefix,
    bool obscure = false,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Color(0xFFD4A574)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: const Color(0xFF8B6F47).withOpacity(0.6)),
        prefixIcon: Icon(prefix, color: const Color(0xFF8B6F47)),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFF3D2817),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4D3827), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4D3827), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8B6F47), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB85C5C), width: 1),
        ),
      ),
    );
  }
}
