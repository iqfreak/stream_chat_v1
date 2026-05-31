import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../services/stream_chat_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_strings.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMsg = null; });
    try {
      final ok = await context.read<StreamChatService>()
          .login(_emailCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;
      if (ok) {
        context.read<AppState>().signIn();
        context.go('/channels');
      } else {
        setState(() { _loading = false; _errorMsg = 'Invalid email or password.'; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _errorMsg = 'Login failed: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Stack(
        children: [
          if (isDark) ...[
            Positioned(top: -80, right: -60,
              child: Container(width: 260, height: 260,
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle))),
            Positioned(bottom: -60, left: -40,
              child: Container(width: 200, height: 200,
                decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.12), shape: BoxShape.circle))),
          ],
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Center(
                        child: Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
                          ),
                          child: const Icon(Icons.chat_rounded, color: Colors.white, size: 36),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Center(child: Text(AppStrings.t(context, 'login_title'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800))),
                      const SizedBox(height: 6),
                      Center(child: Text(AppStrings.t(context, 'login_sub'), style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary))),
                      const SizedBox(height: 36),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(labelText: AppStrings.t(context, 'email'), prefixIcon: const Icon(Icons.email_outlined)),
                        validator: (v) { if (v == null || v.isEmpty) return 'Enter your email'; if (!v.contains('@')) return 'Enter a valid email'; return null; },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: AppStrings.t(context, 'password'),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) { if (v == null || v.isEmpty) return 'Enter your password'; if (v.length < 6) return 'Min 6 characters'; return null; },
                      ),
                      if (_errorMsg != null) ...[
                        const SizedBox(height: 12),
                        Text(_errorMsg!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                      ],
                      const SizedBox(height: 28),
                      ElevatedButton(
                        onPressed: _loading ? null : _login,
                        child: _loading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(AppStrings.t(context, 'login')),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account? ", style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
                          TextButton(
                            onPressed: () => context.go('/register'),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                            child: Text(AppStrings.t(context, 'register')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
