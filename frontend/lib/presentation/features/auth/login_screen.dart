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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(LoginRequested(email: _email.text.trim(), password: _password.text));
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
                Text('Log in', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Welcome back. Pick up right where you left off.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (state.sessionExpired) ...[
                  StatusBanner(
                    tone: tones.warning,
                    icon: Icons.schedule,
                    child: const Text('Your session has expired. Please log in again.'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
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
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
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
                      : const Text('Log in'),
                ),
                TextButton(
                  onPressed: () => context.go(
                    Uri(path: '/signup', queryParameters: from == null ? null : {'from': from}).toString(),
                  ),
                  child: const Text('No account? Sign up'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
