import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    // Simulate authentication delay
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _loading = false);

    // For demo: show success snack
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Login berhasil — selamat datang!'),
          backgroundColor: Colors.tealAccent.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background with subtle noise-like animated radial
          const _AnimatedBackground(),

          // Center card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: size.width > 900 ? 900 : 700),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Floating glows / orbs
                    Positioned(
                      left: -50,
                      top: -60,
                      child: _GlowingOrb(
                        size: 220,
                        colors: const [Color(0xFF00F0FF), Color(0xFF6A00FF)],
                        blurSigma: 60,
                        animationDelay: 0,
                        pulseController: _pulseController,
                      ),
                    ),
                    Positioned(
                      right: -40,
                      bottom: -40,
                      child: _GlowingOrb(
                        size: 180,
                        colors: const [Color(0xFFFF6AC1), Color(0xFF00E6A8)],
                        blurSigma: 50,
                        animationDelay: 800,
                        pulseController: _pulseController,
                      ),
                    ),

                    // Frosted glass card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.06),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.6),
                                offset: const Offset(0, 20),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Left decorative panel (hidden on small screens)
                              if (size.width > 700)
                                Expanded(
                                  flex: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(28),
                                    height: 480,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.02),
                                          Colors.white.withOpacity(0.01),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Opacity(
                                          opacity: 0.9,
                                          child: Text(
                                            'WELCOME',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 2,
                                              color: Colors.white.withOpacity(0.95),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Masuk untuk melanjutkan pengalaman futuristik Anda.',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 13,
                                            color: Colors.white.withOpacity(0.75),
                                          ),
                                        ),
                                        const SizedBox(height: 28),
                                        Row(
                                          children: [
                                            _chipIcon('AI', Color(0xFF7C4DFF)),
                                            const SizedBox(width: 8),
                                            _chipIcon('Secure', Color(0xFF00E6A8)),
                                            const SizedBox(width: 8),
                                            _chipIcon('Fast', Color(0xFFFF6AC1)),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Expanded(
                                          child: Align(
                                            alignment: Alignment.bottomLeft,
                                            child: Opacity(
                                              opacity: 0.85,
                                              child: Text(
                                                'Design • Motion • Security',
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 12,
                                                  color: Colors.white.withOpacity(0.6),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // Form panel
                              Expanded(
                                flex: 5,
                                child: Padding(
                                  padding: const EdgeInsets.all(28.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              _logo(),
                                              const SizedBox(width: 12),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'NeonGate',
                                                    style: GoogleFonts.montserrat(
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.w700,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Sign in',
                                                    style: GoogleFonts.montserrat(
                                                      fontSize: 12,
                                                      color: Colors.white.withOpacity(0.6),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                onPressed: () {},
                                                icon: const Icon(Icons.help_outline_rounded),
                                                color: Colors.white.withOpacity(0.7),
                                              ),
                                              const SizedBox(width: 6),
                                              Transform.scale(
                                                scale: 1.0,
                                                child: InkWell(
                                                  onTap: () {},
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.03),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(
                                                        color: Colors.white.withOpacity(0.04),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.language, size: 16, color: Colors.white70),
                                                        const SizedBox(width: 6),
                                                        Text(
                                                          'ID',
                                                          style: GoogleFonts.montserrat(
                                                            fontSize: 13,
                                                            color: Colors.white70,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 18),
                                      Form(
                                        key: _formKey,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            _NeonInputField(
                                              controller: _emailCtrl,
                                              label: 'Email',
                                              hint: 'you@example.com',
                                              prefix: Icons.email_outlined,
                                              keyboardType: TextInputType.emailAddress,
                                              validator: (v) {
                                                if (v == null || v.isEmpty) return 'Email wajib diisi';
                                                final regex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
                                                if (!regex.hasMatch(v)) return 'Format email tidak valid';
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 12),
                                            _NeonInputField(
                                              controller: _passCtrl,
                                              label: 'Password',
                                              hint: 'Masukkan password Anda',
                                              prefix: Icons.lock_outline,
                                              obscureText: _obscure,
                                              suffix: IconButton(
                                                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                                                color: Colors.white70,
                                                onPressed: () => setState(() => _obscure = !_obscure),
                                              ),
                                              validator: (v) {
                                                if (v == null || v.isEmpty) return 'Password wajib diisi';
                                                if (v.length < 6) return 'Minimal 6 karakter';
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Checkbox(
                                                  value: true,
                                                  onChanged: (_) {},
                                                  checkColor: Colors.black,
                                                  activeColor: Colors.tealAccent,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Ingat saya',
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: 13,
                                                    color: Colors.white.withOpacity(0.78),
                                                  ),
                                                ),
                                                const Spacer(),
                                                TextButton(
                                                  onPressed: () {},
                                                  child: Text(
                                                    'Lupa password?',
                                                    style: GoogleFonts.montserrat(
                                                      color: Colors.blue.shade200,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                            const SizedBox(height: 18),
                                            SizedBox(
                                              height: 52,
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.transparent,
                                                  padding: EdgeInsets.zero,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                                onPressed: _loading ? null : _submit,
                                                child: Ink(
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        const Color(0xFF00E6A8).withOpacity(0.95),
                                                        const Color(0xFF00C2FF).withOpacity(0.95),
                                                      ],
                                                      begin: Alignment.centerLeft,
                                                      end: Alignment.centerRight,
                                                    ),
                                                    borderRadius: BorderRadius.circular(12),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.blueAccent.withOpacity(0.15),
                                                        blurRadius: 12,
                                                        offset: const Offset(0, 6),
                                                      )
                                                    ],
                                                  ),
                                                  child: Center(
                                                    child: _loading
                                                        ? Row(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              const SizedBox(
                                                                width: 18,
                                                                height: 18,
                                                                child: CircularProgressIndicator(
                                                                  color: Colors.white,
                                                                  strokeWidth: 2.0,
                                                                ),
                                                              ),
                                                              const SizedBox(width: 12),
                                                              Text(
                                                                'Memproses...',
                                                                style: GoogleFonts.montserrat(
                                                                  fontSize: 15,
                                                                  color: Colors.black87,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                              ),
                                                            ],
                                                          )
                                                        : Text(
                                                            'MASUK',
                                                            style: GoogleFonts.montserrat(
                                                              fontSize: 15,
                                                              color: Colors.black87,
                                                              fontWeight: FontWeight.w700,
                                                              letterSpacing: 1.2,
                                                            ),
                                                          ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 14),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Container(height: 1, color: Colors.white.withOpacity(0.04)),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                                  child: Text(
                                                    'atau masuk dengan',
                                                    style: GoogleFonts.montserrat(
                                                      fontSize: 12,
                                                      color: Colors.white.withOpacity(0.55),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Container(height: 1, color: Colors.white.withOpacity(0.04)),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                _socialButton(
                                                  icon: Icons.fingerprint,
                                                  label: 'Biometric',
                                                  color: Colors.deepPurpleAccent,
                                                  onTap: () => _showInfo('Biometric login (demo)'),
                                                ),
                                                _socialButton(
                                                  icon: Icons.apple,
                                                  label: 'Apple',
                                                  color: Colors.white,
                                                  onTap: () => _showInfo('Sign in with Apple (demo)'),
                                                ),
                                                _socialButton(
                                                  icon: Icons.g_mobiledata,
                                                  label: 'Google',
                                                  color: Colors.redAccent,
                                                  onTap: () => _showInfo('Sign in with Google (demo)'),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 18),
                                            Center(
                                              child: GestureDetector(
                                                onTap: () {},
                                                child: Text.rich(
                                                  TextSpan(
                                                    text: 'Belum punya akun? ',
                                                    style: GoogleFonts.montserrat(
                                                      fontSize: 13,
                                                      color: Colors.white.withOpacity(0.65),
                                                    ),
                                                    children: [
                                                      TextSpan(
                                                        text: 'Daftar',
                                                        style: GoogleFonts.montserrat(
                                                          fontSize: 13,
                                                          color: Colors.blue.shade200,
                                                          fontWeight: FontWeight.w600,
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
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom-right tiny floating credit
          Positioned(
            right: 18,
            bottom: 12,
            child: Opacity(
              opacity: 0.6,
              child: Text(
                '© NeonGate • 2025',
                style: GoogleFonts.montserrat(fontSize: 11, color: Colors.white70),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _logo() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00E6A8), Color(0xFF00C2FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.cyan.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Center(
        child: Icon(
          Icons.power_settings_new_rounded,
          color: Colors.black,
          size: 26,
        ),
      ),
    );
  }

  Widget _chipIcon(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(fontSize: 12, color: Colors.white),
      ),
    );
  }

  Widget _socialButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.montserrat(fontSize: 13, color: Colors.white70),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showInfo(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _NeonInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefix;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;

  const _NeonInputField({
    Key? key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefix,
    this.suffix,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(fontSize: 12, color: Colors.white.withOpacity(0.75)),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.03)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            validator: validator,
            style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14),
            cursorColor: Colors.cyanAccent,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              hintText: hint,
              hintStyle: GoogleFonts.montserrat(color: Colors.white54, fontSize: 13),
              prefixIcon: Icon(prefix, color: Colors.white70),
              suffixIcon: suffix,
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground({Key? key}) : super(key: key);

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.2 + _anim.value * 0.4, -0.3 + _anim.value * 0.4),
              radius: 1.2,
              colors: [
                const Color(0xFF050311),
                const Color(0xFF050317).withOpacity(0.95),
                const Color(0xFF041227).withOpacity(0.6),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: CustomPaint(
            painter: _GridPainter(phase: _anim.value),
            child: Container(),
          ),
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  final double phase;
  _GridPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 1.0;

    final step = 48.0;
    final offsetAnim = phase * 24;

    for (double x = -step * 2; x < size.width + step * 2; x += step) {
      canvas.drawLine(
        Offset(x + offsetAnim % step, 0),
        Offset(x + offsetAnim % step, size.height),
        paint,
      );
    }
    for (double y = -step * 2; y < size.height + step * 2; y += step) {
      canvas.drawLine(
        Offset(0, y + offsetAnim % step),
        Offset(size.width, y + offsetAnim % step),
        paint,
      );
    }

    // draw subtle diagonal lines
    final diagPaint = Paint()..color = Colors.cyan.withOpacity(0.015);
    for (double i = -size.height; i < size.width; i += 80) {
      canvas.drawLine(Offset(i + offsetAnim * 2, 0), Offset(i + size.height + offsetAnim * 2, size.height), diagPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => oldDelegate.phase != phase;
}

class _GlowingOrb extends StatelessWidget {
  final double size;
  final List<Color> colors;
  final double blurSigma;
  final int animationDelay;
  final AnimationController pulseController;

  const _GlowingOrb({
    Key? key,
    required this.size,
    required this.colors,
    required this.blurSigma,
    required this.animationDelay,
    required this.pulseController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        final t = (pulseController.value + (animationDelay / 1000)) % 1.0;
        final scale = 0.9 + (0.15 * (0.5 + 0.5 * (sin((t * 2 * 3.1415926)))));
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
          boxShadow: [
            BoxShadow(color: colors.first.withOpacity(0.3), blurRadius: blurSigma, spreadRadius: 10),
            BoxShadow(color: colors.last.withOpacity(0.15), blurRadius: blurSigma / 2, spreadRadius: 4),
          ],
        ),
      ),
    );
  }
}
