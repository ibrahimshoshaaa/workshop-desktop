import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final error = await ref.read(authRepositoryProvider).login(
          _usernameController.text,
          _passwordController.text,
        );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _error = error;
    });
  }

  InputDecoration _decoration(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.cairo(fontSize: 13.5),
      prefixIcon: Icon(icon, size: 20, color: AppColors.wood),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFFAF6F0),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.wood, width: 1.6)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.danger, width: 1.2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [AppColors.woodDark, AppColors.wood, Color(0xFFFAF6F0)],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 40, offset: const Offset(0, 20)),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [AppColors.amber, AppColors.wood]),
                        boxShadow: [BoxShadow(color: AppColors.wood.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8))],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          width: 76,
                          height: 76,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Tahoun Royal Home', style: GoogleFonts.cairo(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.woodDark)),
                    const SizedBox(height: 6),
                    Text('سجّل الدخول لإدارة المتجر', style: GoogleFonts.cairo(color: Colors.grey.shade600, fontSize: 13)),
                    const SizedBox(height: 28),
                    if (_error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_error!, style: GoogleFonts.cairo(color: AppColors.danger, fontSize: 12.5)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    TextFormField(
                      controller: _usernameController,
                      autofocus: true,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(fontSize: 14),
                      decoration: _decoration('اليوزر', Icons.person_outline_rounded),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'اكتب اليوزر' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(fontSize: 14),
                      onFieldSubmitted: (_) => _submit(),
                      decoration: _decoration(
                        'كلمة المرور',
                        Icons.lock_outline_rounded,
                        suffix: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20, color: Colors.grey.shade500),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'اكتب كلمة المرور' : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.wood,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text('دخول', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
