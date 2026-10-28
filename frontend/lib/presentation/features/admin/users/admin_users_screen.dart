import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../bloc/auth/auth_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../models/user_model.dart';
import '../../../../repositories/admin_repository.dart';
import '../../../components/admin_list.dart';
import '../../../components/app_snack.dart';
import '../../../components/confirm_dialog.dart';
import '../../../components/empty_state.dart';
import '../../../components/error_state.dart';
import '../../../components/loading_skeleton.dart';
import '../../../components/page_container.dart';
import '../../../components/page_header.dart';
import '../../../components/pager.dart';
import '../../../components/status_banner.dart';
import '../../../components/status_pill.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

enum _UserAction { toggleRole, toggleBlock }

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchController = TextEditingController();
  int _page = 1;
  String _q = '';
  UserPage? _result;
  bool _loading = true;
  String? _error;
  final Set<String> _updating = {};

  AdminRepository get _repo => sl<AdminRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repo.getUsers(page: _page, q: _q);
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong';
        _loading = false;
      });
    }
  }

  void _search(String value) {
    _q = value.trim();
    _page = 1;
    _load();
  }

  void _goToPage(int page) {
    _page = page;
    _load();
  }

  Future<void> _onAction(UserModel user, _UserAction action) async {
    final String successMessage;
    final Future<UserModel> Function() call;
    if (action == _UserAction.toggleRole) {
      final makeAdmin = !user.isAdmin;
      if (!makeAdmin &&
          !await showConfirmDialog(
            context,
            title: 'Make ${user.name} a regular user?',
            message: 'They lose access to the admin area.',
            confirmLabel: 'Make user',
          )) {
        return;
      }
      successMessage = 'Role updated';
      call = () => _repo.setUserRole(user.id, makeAdmin ? UserModel.roleAdmin : UserModel.roleUser);
    } else {
      final block = !user.isBlocked;
      if (block &&
          !await showConfirmDialog(
            context,
            title: 'Block ${user.name}?',
            message: 'They are signed out on their next request and cannot log in.',
            confirmLabel: 'Block',
            destructive: true,
          )) {
        return;
      }
      successMessage = block ? 'User blocked' : 'User unblocked';
      call = () => _repo.setUserBlocked(user.id, block);
    }
    if (!mounted) return;
    setState(() => _updating.add(user.id));
    try {
      final updated = await call();
      if (!mounted) return;
      setState(() {
        _updating.remove(user.id);
        final result = _result;
        if (result != null) {
          _result = UserPage(
            items: [for (final u in result.items) u.id == updated.id ? updated : u],
            page: result.page,
            pages: result.pages,
            total: result.total,
          );
        }
      });
      showAppSnack(context, successMessage);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _updating.remove(user.id));
      showAppSnack(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _updating.remove(user.id));
      showAppSnack(context, 'Something went wrong');
    }
  }

  Future<void> _createUser() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const _CreateUserDialog(),
    );
    if (created == true && mounted) {
      showAppSnack(context, 'User created');
      await _load();
    }
  }

  Widget _toolbar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: 'Search name or email',
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Clear',
            onPressed: () {
              _searchController.clear();
              _search('');
            },
          ),
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: _search,
      ),
    );
  }

  static const _columns = [
    AdminColumn('User', flex: 4),
    AdminColumn('Role', flex: 2),
    AdminColumn('Status', flex: 2),
    AdminColumn('Actions'),
  ];

  Widget _avatar(UserModel u, double radius) =>
      CircleAvatar(radius: radius, child: Text(u.name.isEmpty ? '?' : u.name[0].toUpperCase()));

  Widget _actionsFor(UserModel u, bool isMe) {
    if (_updating.contains(u.id)) {
      return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
    }
    return PopupMenuButton<_UserAction>(
      enabled: !isMe,
      tooltip: 'Actions',
      onSelected: (action) => _onAction(u, action),
      itemBuilder: (_) => [
        PopupMenuItem(value: _UserAction.toggleRole, child: Text(u.isAdmin ? 'Make user' : 'Make admin')),
        PopupMenuItem(value: _UserAction.toggleBlock, child: Text(u.isBlocked ? 'Unblock' : 'Block')),
      ],
    );
  }

  Widget _tableRow(UserModel u, String? myId) {
    final theme = Theme.of(context);
    final colors = StatusColors.of(context);
    final isMe = u.id == myId;
    final name = isMe ? '${u.name} (you)' : u.name;
    return AdminTableRow(
      columns: _columns,
      cells: [
        Row(
          children: [
            _avatar(u, 16),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    u.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: StatusPill(label: u.isAdmin ? 'Admin' : 'User', tone: u.isAdmin ? colors.info : colors.neutral),
        ),
        u.isBlocked
            ? FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: StatusPill(label: 'Blocked', tone: colors.danger),
              )
            : const Text('–'),
        _actionsFor(u, isMe),
      ],
    );
  }

  Widget _card(UserModel u, String? myId) {
    final theme = Theme.of(context);
    final colors = StatusColors.of(context);
    final isMe = u.id == myId;
    final name = isMe ? '${u.name} (you)' : u.name;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _avatar(u, 20),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(
                        u.email,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _actionsFor(u, isMe),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                StatusPill(label: u.isAdmin ? 'Admin' : 'User', tone: u.isAdmin ? colors.info : colors.neutral),
                if (u.isBlocked) StatusPill(label: 'Blocked', tone: colors.danger),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<AuthBloc>().state.user?.id;
    return PageContainer(
      scroll: false,
      child: LayoutBuilder(
        builder: (context, c) {
          final table = c.maxWidth >= kAdminTableMinWidth;
          final result = _result;
          final users = result?.items ?? const <UserModel>[];
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: PageHeader(
                  title: 'Users',
                  actions: [
                    FilledButton.icon(
                      onPressed: _createUser,
                      icon: const Icon(Icons.person_add),
                      label: const Text('New user'),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(child: _toolbar()),
              if (_loading && result == null)
                const SliverToBoxAdapter(child: ListSkeleton(rows: 6))
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorState(message: _error!, onRetry: _load),
                )
              else if (users.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(icon: Icons.people_outline, title: 'No users found'),
                )
              else if (table)
                SliverToBoxAdapter(
                  child: AdminListCard(columns: _columns, rows: [for (final u in users) _tableRow(u, myId)]),
                )
              else
                SliverList.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (_, i) => _card(users[i], myId),
                ),
              if (result != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Pager(
                      page: result.page,
                      pages: result.pages,
                      total: result.total,
                      noun: 'users',
                      loading: _loading,
                      onPage: _goToPage,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CreateUserDialog extends StatefulWidget {
  const _CreateUserDialog();

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = UserModel.roleUser;
  bool _saving = false;
  String? _serverError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _serverError = null;
    });
    try {
      await sl<AdminRepository>().createUser(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        role: _role,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _serverError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _serverError = 'Something went wrong';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New user'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  maxLength: 50,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) {
                    final n = v?.trim().length ?? 0;
                    return (n < 2 || n > 50) ? 'Name must be 2 to 50 characters' : null;
                  },
                ),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) {
                    final e = v?.trim() ?? '';
                    return (e.isEmpty || !e.contains('@')) ? 'Enter a valid email' : null;
                  },
                ),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (v) => (v == null || v.length < 8) ? 'Password must be at least 8 characters' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: UserModel.roleUser, child: Text('User')),
                    DropdownMenuItem(value: UserModel.roleAdmin, child: Text('Admin')),
                  ],
                  onChanged: (v) => setState(() => _role = v ?? UserModel.roleUser),
                ),
                if (_serverError != null) ...[
                  const SizedBox(height: 12),
                  StatusBanner(
                    tone: StatusColors.of(context).danger,
                    icon: Icons.error_outline,
                    child: Text(_serverError!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: _saving ? null : _save, child: const Text('Save')),
      ],
    );
  }
}
