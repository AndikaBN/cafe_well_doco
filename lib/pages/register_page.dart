import 'package:flutter/material.dart';
import 'package:cafe_well_doco/services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _inviteCode = TextEditingController();
  final _authService = AuthService();

  bool _obscurePwd = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;
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
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    _inviteCode.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan setujui syarat & ketentuan')),
      );
      return;
    }

    setState(() => _loading = true);

    final result = await _authService.registerWithEmail(
      email: _email.text.trim(),
      password: _password.text.trim(),
      displayName: _fullName.text.trim(),
      inviteCode: _inviteCode.text.trim().isNotEmpty
          ? _inviteCode.text.trim()
          : null,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              result['success'] ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(result['message'])),
          ],
        ),
        backgroundColor: result['success']
            ? Colors.green.shade600
            : Colors.red.shade600,
      ),
    );
    print(result);

    // Jika berhasil, kembali ke login page
    if (result['success']) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = 520.0;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: _SkyBackground()),

            // floating circle accent
            Positioned(
              left: -60,
              bottom: 40,
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
                  opacity: 0.14,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.lightBlue.shade200],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 36,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueGrey.shade50,
                              blurRadius: 20,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 18,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      width: 86,
                                      height: 86,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        border: Border.all(
                                          color: Colors.lightBlue.shade100,
                                          width: 2,
                                        ),
                                      ),
                                      child: Image.asset(
                                        "assets/images/coffe-logo.jpeg",
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                // Full name
                                _buildField(
                                  controller: _fullName,
                                  hint: 'Nama lengkap',
                                  prefix: Icons.person_outline,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty)
                                      return 'Nama tidak boleh kosong';
                                    if (v.trim().length < 2)
                                      return 'Nama terlalu pendek';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
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
                                const SizedBox(height: 12),
                                // Phone (optional)
                                _buildField(
                                  controller: _phone,
                                  hint: 'Nomor telepon (opsional)',
                                  prefix: Icons.phone_iphone,
                                  keyboardType: TextInputType.phone,
                                  validator: (v) {
                                    if (v != null &&
                                        v.trim().isNotEmpty &&
                                        !RegExp(r'^[0-9+\-\s]+$').hasMatch(v))
                                      return 'Nomor telepon tidak valid';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                // Password
                                _buildField(
                                  controller: _password,
                                  hint: 'Password',
                                  prefix: Icons.lock_outline,
                                  obscure: _obscurePwd,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscurePwd
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.blueGrey.shade400,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscurePwd = !_obscurePwd,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Password tidak boleh kosong';
                                    if (v.length < 6)
                                      return 'Password minimal 6 karakter';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                // Confirm password
                                _buildField(
                                  controller: _confirm,
                                  hint: 'Konfirmasi password',
                                  prefix: Icons.lock,
                                  obscure: _obscureConfirm,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.blueGrey.shade400,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Konfirmasi password tidak boleh kosong';
                                    if (v != _password.text)
                                      return 'Password tidak cocok';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                // Invite Code (optional)
                                _buildField(
                                  controller: _inviteCode,
                                  hint: 'Kode undangan (opsional)',
                                  prefix: Icons.confirmation_number_outlined,
                                  validator: (v) {
                                    // Optional field, no validation needed
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                // Checkbox Terms
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _acceptTerms,
                                      onChanged: (val) => setState(
                                        () => _acceptTerms = val ?? false,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Saya menyetujui syarat & ketentuan',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.blueGrey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 22),
                                // Register button
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _onRegister,
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
                                                'Daftar',
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
                                const SizedBox(height: 12),

                                // Login hint
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Sudah punya akun?',
                                      style: TextStyle(
                                        color: Colors.blueGrey.shade600,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(
                                          context,
                                        ).pop(); // kembali ke login
                                      },
                                      child: Text(
                                        'Masuk',
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

                      const SizedBox(height: 14),
                      Text(
                        'Akunmu aman bersama kami • Privasi terjaga',
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
          ],
        ),
      ),
    );
  }

  // Reusable input builder
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
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// Simple sky background (reused from login)
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

    drawCloud(size.width * 0.18, size.height * 0.16, 1.0);
    drawCloud(size.width * 0.6, size.height * 0.12, 0.9);
    drawCloud(size.width * 0.45, size.height * 0.33, 1.1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
