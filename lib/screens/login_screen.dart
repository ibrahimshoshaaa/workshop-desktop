import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(String correctPassword) {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text == correctPassword) {
      ref.read(isLoggedInProvider.notifier).state = true;
    } else {
      setState(() => _error = 'كلمة المرور غير صحيحة');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authSettingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      body: Center(
        child: authAsync.when(
          data: (settings) => Container(
            width: 380,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(radius: 32, backgroundColor: AppColors.wood, child: Icon(Icons.chair_alt_rounded, color: AppColors.amber, size: 32)),
                  const SizedBox(height: 16),
                  const Text('ورشة التنجيد والأثاث', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.woodDark)),
                  const SizedBox(height: 4),
                  const Text('من فضلك أدخل كلمة المرور للمتابعة', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    autofocus: true,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    onFieldSubmitted: (_) => _submit(settings.password),
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      errorText: _error,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'اكتب كلمة المرور' : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () => _submit(settings.password),
                      child: const Text('دخول'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('حصل خطأ: $e'),
        ),
      ),
    );
  }
}
