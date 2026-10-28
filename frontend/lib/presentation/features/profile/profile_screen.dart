import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/status_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../models/user_model.dart';
import '../../../repositories/auth_repository.dart';
import '../../components/app_snack.dart';
import '../../components/page_container.dart';
import '../../components/section_card.dart';
import '../../components/status_pill.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _current = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirm = TextEditingController();

  bool _savingName = false;
  bool _savingPassword = false;
  bool _nameInitialized = false;
  String? _nameError;
  String? _currentError;
  String? _newPasswordError;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _name.dispose();
    _current.dispose();
    _newPassword.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final bloc = context.read<AuthBloc>();
    try {
      final user = await sl<AuthRepository>().getProfile();
      bloc.add(UserUpdated(user));
    } on ApiException {
      // The cached user from the session is still shown.
    } catch (_) {
      // Unexpected response; the cached user is still shown.
    }
  }

  Future<void> _saveName() async {
    if (!_nameFormKey.currentState!.validate()) return;
    final bloc = context.read<AuthBloc>();
    setState(() {
      _savingName = true;
      _nameError = null;
    });
    try {
      final user = await sl<AuthRepository>().updateName(_name.text.trim());
      bloc.add(UserUpdated(user));
      if (!mounted) return;
      setState(() => _savingName = false);
      showAppSnack(context, 'Name updated');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _savingName = false;
        if (!e.isUnauthorized) _nameError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _savingName = false;
        _nameError = 'Something went wrong';
      });
    }
  }

  Future<void> _changePassword() async {
    setState(() {
      _currentError = null;
      _newPasswordError = null;
    });
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() => _savingPassword = true);
    try {
      await sl<AuthRepository>().changePassword(
        currentPassword: _current.text,
        newPassword: _newPassword.text,
      );
      if (!mounted) return;
      _current.clear();
      _newPassword.clear();
      _confirm.clear();
      setState(() => _savingPassword = false);
      showAppSnack(context, 'Password changed');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _savingPassword = false;
        if (e.isUnauthorized) return;
        if (e.code == 'INVALID_CURRENT_PASSWORD') {
          _currentError = 'Current password is incorrect';
        } else {
          _newPasswordError = e.message;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _savingPassword = false;
        _newPasswordError = 'Something went wrong';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    if (user == null) return const SizedBox.shrink();
    if (!_nameInitialized) {
      _name.text = user.name;
      _nameInitialized = true;
    }
    final nameUnchanged = _name.text.trim() == user.name;
    final memberSince = user.createdAt == null
        ? '-'
        : formatOrderDate(user.createdAt);

    final Widget body = context.isDesktop
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _accountCard(user, memberSince)),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _nameCard(nameUnchanged),
                    const SizedBox(height: AppSpacing.lg),
                    _passwordCard(),
                  ],
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _accountCard(user, memberSince),
              const SizedBox(height: AppSpacing.lg),
              _nameCard(nameUnchanged),
              const SizedBox(height: AppSpacing.lg),
              _passwordCard(),
            ],
          );

    return PageContainer(
      maxWidth: AppWidths.narrow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(user),
          const SizedBox(height: AppSpacing.xl),
          body,
        ],
      ),
    );
  }

  Widget _header(UserModel user) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final initial = user.name.trim().isEmpty
        ? '?'
        : user.name.trim().substring(0, 1).toUpperCase();
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: scheme.secondaryContainer,
          child: Text(
            initial,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: scheme.onSecondaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: context.isPhone
                    ? theme.textTheme.headlineSmall
                    : theme.textTheme.headlineMedium,
              ),
              Text(
                user.email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              StatusPill(
                label: user.isAdmin ? 'Admin' : 'Customer',
                tone: user.isAdmin
                    ? StatusColors.of(context).info
                    : StatusColors.of(context).neutral,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _accountCard(UserModel user, String memberSince) => SectionCard(
    title: 'Account',
    child: Column(
      children: [
        _row('Name', user.name),
        _row('Email', user.email),
        _row('Role', user.isAdmin ? 'Admin' : 'Customer'),
        _row('Member since', memberSince),
      ],
    ),
  );

  Widget _spinner() => const SizedBox(
    width: 18,
    height: 18,
    child: CircularProgressIndicator(strokeWidth: 2),
  );

  Widget _nameCard(bool nameUnchanged) {
    final button = FilledButton(
      onPressed: (_savingName || nameUnchanged) ? null : _saveName,
      child: _savingName ? _spinner() : const Text('Save'),
    );
    return SectionCard(
      title: 'Display name',
      child: Form(
        key: _nameFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(
                labelText: 'Name',
                prefixIcon: const Icon(Icons.person_outline),
                errorText: _nameError,
              ),
              onChanged: (_) => setState(() => _nameError = null),
              validator: (v) {
                final n = v?.trim().length ?? 0;
                return (n < 2 || n > 50)
                    ? 'Name must be 2 to 50 characters'
                    : null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            context.isPhone
                ? button
                : Align(alignment: Alignment.centerRight, child: button),
          ],
        ),
      ),
    );
  }

  Widget _eye(bool visible, VoidCallback onTap) => IconButton(
    tooltip: visible ? 'Hide password' : 'Show password',
    icon: Icon(
      visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
    ),
    onPressed: onTap,
  );

  Widget _passwordCard() {
    final button = FilledButton(
      onPressed: _savingPassword ? null : _changePassword,
      child: _savingPassword ? _spinner() : const Text('Change password'),
    );
    return SectionCard(
      title: 'Change password',
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _current,
              obscureText: !_showCurrent,
              decoration: InputDecoration(
                labelText: 'Current password',
                prefixIcon: const Icon(Icons.lock_outline),
                errorText: _currentError,
                suffixIcon: _eye(
                  _showCurrent,
                  () => setState(() => _showCurrent = !_showCurrent),
                ),
              ),
              onChanged: (_) {
                if (_currentError != null) setState(() => _currentError = null);
              },
              validator: (v) => (v == null || v.isEmpty)
                  ? 'Current password is required'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _newPassword,
              obscureText: !_showNew,
              decoration: InputDecoration(
                labelText: 'New password',
                prefixIcon: const Icon(Icons.lock_outline),
                errorText: _newPasswordError,
                suffixIcon: _eye(
                  _showNew,
                  () => setState(() => _showNew = !_showNew),
                ),
              ),
              onChanged: (_) {
                if (_newPasswordError != null) {
                  setState(() => _newPasswordError = null);
                }
              },
              validator: (v) => (v == null || v.length < 8)
                  ? 'Password must be at least 8 characters'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _confirm,
              obscureText: !_showConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm new password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: _eye(
                  _showConfirm,
                  () => setState(() => _showConfirm = !_showConfirm),
                ),
              ),
              validator: (v) =>
                  v != _newPassword.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            context.isPhone
                ? button
                : Align(alignment: Alignment.centerRight, child: button),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
