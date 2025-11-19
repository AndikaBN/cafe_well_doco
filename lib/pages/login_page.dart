import 'dart:async';
import 'dart:ui';

import 'package:cafe_well_doco/pages/register_page.dart';
import 'package:cafe_well_doco/services/auth_service.dart';
import 'package:cafe_well_doco/pages/admin_home_page.dart';
import 'package:cafe_well_doco/pages/karyawan_home_page.dart';
import 'package:flutter/material.dart';

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

  late final AnimationController _floatController;
  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
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
      final user = result['user'];

      // Navigate berdasarkan role
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
      body: SafeArea(
        child: Stack(
          children: [
            // Sky gradient background with subtle clouds
            const Positioned.fill(child: _SkyBackground()),
            // Floating decorative circle (animated)
            Positioned(
              right: -60,
              top: 40,
              child: AnimatedBuilder(
                animation: _floatController,
                builder: (context, child) {
                  final dy = 12 * (_floatController.value - 0.5);
                  return Transform.translate(
                    offset: Offset(0, dy),
                    child: child,
                  );
                },
                child: Opacity(
                  opacity: 0.18,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.lightBlue.shade200, Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
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
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.shade50,
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              "assets/images/coffe-logo.jpeg",
                              width: 42,
                              height: 42,
                              fit: BoxFit.fill,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome to Coffe Well Doco',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.blueGrey.shade900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Masuk ke akun kamu',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blueGrey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      // Card (frost-like but bright)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueGrey.shade50,
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 20,
                          ),
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
                                const SizedBox(height: 14),
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
                                      color: Colors.blueGrey.shade400,
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
                                const SizedBox(height: 32),
                                // Sign in button
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _onSignIn,
                                    style: ElevatedButton.styleFrom(
                                      elevation: 6,
                                      backgroundColor: Colors.transparent,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      shadowColor: Colors.lightBlue.shade100,
                                    ),
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF6BB7FF),
                                            Color(0xFF3A9BFF),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Container(
                                        alignment: Alignment.center,
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
                                                          color: Colors.white,
                                                          strokeWidth: 2,
                                                        ),
                                                  ),
                                                  SizedBox(width: 12),
                                                  Text(
                                                    'Memproses...',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : const Text(
                                                'Masuk',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // signup hint
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Belum punya akun?',
                                      style: TextStyle(
                                        color: Colors.blueGrey.shade600,
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
                                          color: Colors.lightBlue.shade700,
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
                      const SizedBox(height: 18),
                      // subtle note
                      Text(
                        'Didesain untuk pengalaman yang ringan & cepat',
                        style: TextStyle(
                          color: Colors.blueGrey.shade400,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Top-left small weather card (decor)
            Positioned(
              left: 18,
              top: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueGrey.shade50,
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.wb_sunny,
                      color: Colors.orange.shade400,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sunny',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey.shade800,
                          ),
                        ),
                        Text(
                          '26°C',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blueGrey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
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
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.blueGrey.shade300),
        prefixIcon: Icon(prefix, color: Colors.blueGrey.shade300),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _SkyBackground extends StatelessWidget {
  const _SkyBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SkyPainter(), child: Container());
  }
}

class _SkyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFe8f6ff),
          const Color(0xFFdff4ff),
          const Color(0xFFbfe8ff),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    // faint cloud blobs
    final cloudPaint = Paint()..color = Colors.white.withOpacity(0.75);
    void drawCloud(double cx, double cy, double scale) {
      canvas.drawCircle(Offset(cx - 60 * scale, cy), 30 * scale, cloudPaint);
      canvas.drawCircle(
        Offset(cx - 20 * scale, cy - 8 * scale),
        36 * scale,
        cloudPaint,
      );
      canvas.drawCircle(Offset(cx + 20 * scale, cy), 30 * scale, cloudPaint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - 60 * scale, cy, 160 * scale, 28 * scale),
          Radius.circular(14 * scale),
        ),
        cloudPaint,
      );
    }

    // place few clouds
    drawCloud(size.width * 0.2, size.height * 0.18, 1.0);
    drawCloud(size.width * 0.65, size.height * 0.12, 0.8);
    drawCloud(size.width * 0.5, size.height * 0.35, 1.2);
    drawCloud(size.width * 0.18, size.height * 0.48, 0.7);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
