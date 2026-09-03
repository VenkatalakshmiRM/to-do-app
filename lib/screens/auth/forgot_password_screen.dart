import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_deep_link_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _emailSent
                      ? ForgotPasswordConfirmation(
                          email: _emailController.text.trim(),
                        )
                      : _buildRequestForm(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.lock_reset_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 52,
          ),
          const SizedBox(height: 16),
          Text(
            'Password recovery',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your account email and we’ll send you a password reset link.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextFormField(
            key: const ValueKey('forgot-password-email-field'),
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              final email = value?.trim() ?? '';
              final isValid = RegExp(
                r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
              ).hasMatch(email);
              return isValid ? null : 'Enter a valid email address';
            },
            onFieldSubmitted: (_) => _sendResetEmail(),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              key: const ValueKey('forgot-password-error-message'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            key: const ValueKey('send-reset-email-button'),
            onPressed: _isLoading ? null : _sendResetEmail,
            child: _isLoading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Send reset link'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
        redirectTo: AuthDeepLinkConfig.redirectUrl,
      );
      if (mounted) setState(() => _emailSent = true);
    } on AuthException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (error) {
      if (mounted) setState(() => _errorMessage = 'Network error: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class ForgotPasswordConfirmation extends StatelessWidget {
  const ForgotPasswordConfirmation({required this.email, super.key});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('forgot-password-confirmation'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.mark_email_read_outlined,
          color: Theme.of(context).colorScheme.secondary,
          size: 64,
        ),
        const SizedBox(height: 18),
        Text(
          'Check your email for a reset link',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Text(
          'We sent password reset instructions to $email.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 22),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back to login'),
        ),
      ],
    );
  }
}
