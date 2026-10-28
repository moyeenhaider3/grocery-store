import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/auth/auth_state.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/status_colors.dart';
import '../../components/status_banner.dart';
import 'auth_layout.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          SignupRequested(name: _name.text.trim(), email: _email.text.trim(), password: _password.text),
        );
  }

  @override
  Widget build(BuildContext context) {
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    return AuthLayout(
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final loading = state.status == AuthStatus.loading;
          final tones = StatusColors.of(context);
          return Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Sign up', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Create an account to start shopping.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) {
                    final n = v?.trim().length ?? 0;
                    return (n < 2 || n > 50) ? 'Name must be 2-50 characters' : null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _password,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Show password' : 'Hide password',
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  obscureText: _obscure,
                  onFieldSubmitted: (_) => loading ? null : _submit(),
                  validator: (v) => (v == null || v.length < 8) ? 'At least 8 characters' : null,
                ),
                if (state.status == AuthStatus.error && state.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  StatusBanner(tone: tones.danger, icon: Icons.error_outline, child: Text(state.errorMessage!)),
                ],
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: loading ? null : _submit,
                  child: loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Create account'),
                ),
                TextButton(
                  onPressed: () => context.go(
                    Uri(path: '/login', queryParameters: from == null ? null : {'from': from}).toString(),
                  ),
                  child: const Text('Already have an account? Log in'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
