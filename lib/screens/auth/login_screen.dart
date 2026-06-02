import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/firebase_auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuthService _auth = FirebaseAuthService();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  bool _isRegister = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // Returns to the AuthGate root, which now shows the AppShell.
  void _exitToApp() {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _run(Future<User?> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await action();
      if (user != null) {
        _exitToApp();
      } else if (mounted) {
        setState(() => _error = 'Sign-in failed. Please try again.');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = e.message ?? 'Authentication error.');
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _submitEmail() {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    _run(() => _isRegister
        ? _auth.registerWithEmail(email, password)
        : _auth.signInWithEmail(email, password));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              child: AppCard(
                padding: const EdgeInsets.all(AppTheme.spaceLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isRegister ? 'Create account' : 'Welcome back',
                      style: textTheme.displayMedium,
                    ),
                    const SizedBox(height: AppTheme.spaceXS),
                    Text(
                      _isRegister
                          ? 'Sign up to report hot zones and save cool spots.'
                          : 'Sign in to report hot zones and save cool spots.',
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppTheme.spaceLG),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      enabled: !_busy,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'nick@example.com',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceSM),
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      enabled: !_busy,
                      onSubmitted: (_) => _submitEmail(),
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppTheme.spaceSM),
                      Text(
                        _error!,
                        style: textTheme.bodySmall?.copyWith(color: AppTheme.riskExtreme),
                      ),
                    ],
                    const SizedBox(height: AppTheme.spaceMD),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _busy ? null : _submitEmail,
                        child: _busy
                            ? const _ButtonSpinner()
                            : Text(_isRegister ? 'Create account' : 'Sign in'),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceSM),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : () => _run(_auth.signInWithGoogle),
                        icon: const Icon(Icons.g_mobiledata, size: 24),
                        label: const Text('Continue with Google'),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceSM),
                    Center(
                      child: TextButton(
                        onPressed: _busy ? null : () => _run(_auth.signInAnonymously),
                        child: const Text('Continue as guest'),
                      ),
                    ),
                    const Divider(height: AppTheme.spaceLG),
                    Center(
                      child: TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                  _isRegister = !_isRegister;
                                  _error = null;
                                }),
                        child: Text(
                          _isRegister
                              ? 'Already have an account? Sign in'
                              : "New here? Create an account",
                        ),
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

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 18,
      width: 18,
      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textOnDark),
    );
  }
}
