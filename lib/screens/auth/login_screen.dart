import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'forgot_password_screen.dart';
import 'signup_screen.dart';
import '../../services/auth_deep_link_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _LoginIllustration(),
                    const SizedBox(height: 20),
                    Text(
                      'Campus To-Do',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      key: const ValueKey('login-email-field'),
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        final isValid = RegExp(
                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                        ).hasMatch(email);
                        if (!isValid) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const ValueKey('login-password-field'),
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _signInWithEmail(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        key: const ValueKey('forgot-password-button'),
                        onPressed: _openForgotPassword,
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _errorMessage!,
                        key: const ValueKey('login-error-message'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const ValueKey('email-sign-in-button'),
                      onPressed: _isLoading ? null : _signInWithEmail,
                      child: _isLoading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sign in'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SignInButton(
                      Buttons.google,
                      key: const ValueKey('google-sign-in-button'),
                      text: 'Continue with Google',
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFDADCE0)),
                      ),
                      onPressed: () async {
                        if (_isLoading) return;
                        await _signInWithGoogle();
                      },
                    ),
                    const SizedBox(height: 12),
                    SignInButton(
                      Buttons.appleDark,
                      key: const ValueKey('apple-sign-in-button'),
                      text: 'Sign in with Apple',
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onPressed: () async {
                        if (_isLoading) return;
                        await _signInWithApple();
                      },
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      key: const ValueKey('open-signup-button'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SignupScreen(),
                          ),
                        );
                      },
                      child: const Text('New here? Create an account'),
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

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    await _runAuthAction(() async {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (response.session == null) {
        throw const AuthException('Sign-in did not create a session.');
      }
    });
  }

  Future<void> _signInWithGoogle() async {
    await _signInWithOAuth(OAuthProvider.google);
  }

  Future<void> _signInWithApple() async {
    await _signInWithOAuth(OAuthProvider.apple);
  }

  Future<void> _signInWithOAuth(OAuthProvider provider) async {
    await _runAuthAction(() async {
      await Supabase.instance.client.auth.signInWithOAuth(
        provider,
        redirectTo: kIsWeb ? null : AuthDeepLinkConfig.redirectUrl,
      );
    });
  }

  void _openForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  Future<void> _runAuthAction(Future<void> Function() action) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await action();
    } on AuthException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error: $error';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _LoginIllustration extends StatelessWidget {
  const _LoginIllustration();

  @override
  Widget build(BuildContext context) {
    // TODO: replace with illustration asset.
    return Container(
      height: 170,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7292A9), Color(0xFFF1B17F)],
        ),
      ),
      child: const Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: -52,
            left: -20,
            right: -20,
            child: Icon(
              Icons.landscape_rounded,
              size: 220,
              color: Color(0xFF385A70),
            ),
          ),
          Icon(Icons.task_alt_rounded, size: 58, color: Colors.white),
        ],
      ),
    );
  }
}
