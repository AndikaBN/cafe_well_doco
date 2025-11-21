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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 28,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Logo
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF3D2817),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF8B6F47,
                                        ).withOpacity(0.3),
                                        blurRadius: 15,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    "assets/images/logo-coffe.png",
                                    width: 60,
                                    height: 60,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Daftar Akun Baru',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFD4A574),
                                  ),
                                ),
                                const SizedBox(height: 24),
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
                                    Expanded(
                                      child: Text(
                                        'Saya menyetujui syarat & ketentuan',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: const Color(0xFFB8956A),
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
                                            'Daftar',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Login hint
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Sudah punya akun?',
                                      style: TextStyle(
                                        color: const Color(0xFF8B6F47),
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
                      Text(
                        '☕ Join Our Coffee Community',
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
          vertical: 14,
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
