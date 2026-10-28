import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/cart/cart_bloc.dart';
import '../../bloc/cart/cart_state.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/status_colors.dart';
import '../../models/user_model.dart';
import '../components/app_snack.dart';
import '../components/brand_mark.dart';
import '../components/status_pill.dart';
import 'admin_layout.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final user = state.status == AuthStatus.authenticated ? state.user : null;
    final itemCount = context.watch<CartBloc>().state.cart.itemCount;
    final phone = context.isPhone;
    final path = GoRouterState.of(context).uri.path;
    final adminArea = user != null && user.isAdmin && isAdminPath(path);
    return Scaffold(
      drawer: adminArea && phone ? AdminDrawer(path: path) : null,
      appBar: _Header(user: user, itemCount: itemCount, adminArea: adminArea, path: path),
      body: BlocListener<CartBloc, CartState>(
        listenWhen: (prev, curr) => curr.messageSeq != prev.messageSeq && curr.message != null,
        listener: (context, cart) {
          showAppSnack(
            context,
            cart.message!,
            error: cart.messageIsError,
            action: cart.message == 'Added to cart'
                ? SnackBarAction(label: 'View cart', onPressed: () => context.go('/cart'))
                : null,
          );
        },
        child: adminArea ? AdminLayout(path: path, child: child) : child,
      ),
    );
  }
}

/// Store header. In the store its content lines up with the page column; in the admin area it
/// spans the full width next to the rail.
class _Header extends StatelessWidget implements PreferredSizeWidget {
  final UserModel? user;
  final int itemCount;
  final bool adminArea;
  final String path;

  const _Header({required this.user, required this.itemCount, required this.adminArea, required this.path});

  @override
  Size get preferredSize => const Size.fromHeight(AppSizes.headerHeight);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final phone = context.isPhone;
    final user = this.user;
    final gutter = context.gutter;

    final actions = <Widget>[
      if (user != null && user.isAdmin && !phone && !adminArea)
        TextButton.icon(
          onPressed: () => context.go('/admin'),
          icon: const Icon(Icons.dashboard_customize_outlined, size: 18),
          label: const Text('Admin'),
        ),
      if (user != null) ...[
        const SizedBox(width: AppSpacing.xs),
        _CartButton(itemCount: itemCount, active: path == '/cart' || path == '/checkout'),
        const SizedBox(width: AppSpacing.sm),
        _AccountMenu(user: user),
      ] else if (!phone) ...[
        TextButton(onPressed: () => context.go('/login'), child: const Text('Log in')),
        const SizedBox(width: AppSpacing.sm),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 42)),
          onPressed: () => context.go('/signup'),
          child: const Text('Sign up'),
        ),
      ] else
        MenuAnchor(
          builder: (context, controller, _) => IconButton(
            tooltip: 'Account',
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => controller.isOpen ? controller.close() : controller.open(),
          ),
          menuChildren: [
            MenuItemButton(onPressed: () => context.go('/login'), child: const Text('Log in')),
            MenuItemButton(onPressed: () => context.go('/signup'), child: const Text('Sign up')),
          ],
        ),
    ];

    final row = Row(
      children: [
        if (adminArea && phone)
          Builder(
            builder: (ctx) => IconButton(
              tooltip: 'Admin menu',
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
        BrandMark(onTap: () => context.go('/')),
        if (adminArea && !phone) ...[
          const SizedBox(width: AppSpacing.md),
          StatusPill(label: 'Admin', tone: StatusColors.of(context).neutral, dot: false),
        ],
        const Spacer(),
        ...actions,
      ],
    );

    return Material(
      color: scheme.surface,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: AppSizes.headerHeight,
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: scheme.outlineVariant))),
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: adminArea ? double.infinity : AppWidths.content),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: phone ? AppSpacing.sm + 4 : gutter),
                child: row,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  final int itemCount;
  final bool active;

  const _CartButton({required this.itemCount, required this.active});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Cart, $itemCount items',
      child: IconButton(
        tooltip: 'Cart',
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          backgroundColor: active ? scheme.primary : scheme.surfaceContainerLowest,
          foregroundColor: active ? scheme.onPrimary : scheme.onSurface,
          side: BorderSide(color: active ? scheme.primary : scheme.outlineVariant),
        ),
        icon: Badge(
          isLabelVisible: itemCount > 0,
          offset: const Offset(10, -10),
          label: Text('$itemCount'),
          child: const Icon(Icons.shopping_bag_outlined, size: 22),
        ),
        onPressed: () => context.go('/cart'),
      ),
    );
  }
}

class _AccountMenu extends StatelessWidget {
  final UserModel user;

  const _AccountMenu({required this.user});

  String get _initial => user.name.trim().isEmpty ? '?' : user.name.trim()[0].toUpperCase();

  Widget _avatar(BuildContext context, double radius) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.secondaryContainer,
      child: Text(
        _initial,
        style: theme.textTheme.labelLarge?.copyWith(color: scheme.onSecondaryContainer, fontWeight: FontWeight.w800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final phone = context.isPhone;
    final firstName = user.name.trim().split(RegExp(r'\s+')).first;
    return MenuAnchor(
      alignmentOffset: const Offset(0, 8),
      builder: (context, controller, _) {
        void toggle() => controller.isOpen ? controller.close() : controller.open();
        if (phone) {
          return IconButton(tooltip: user.name, icon: _avatar(context, 16), onPressed: toggle);
        }
        return Tooltip(
          message: user.name,
          child: InkWell(
            onTap: toggle,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              height: 44,
              padding: const EdgeInsets.only(left: 4, right: 10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _avatar(context, 17),
                  const SizedBox(width: AppSpacing.sm),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Text(firstName, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelLarge),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.expand_more_rounded, size: 18, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        );
      },
      menuChildren: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 260, maxWidth: 300),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
            child: Row(
              children: [
                _avatar(context, 22),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: theme.textTheme.titleSmall, overflow: TextOverflow.ellipsis),
                      Text(
                        user.email,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      StatusPill(label: user.role, tone: StatusColors.of(context).neutral, dot: false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: AppSpacing.sm + 1),
        MenuItemButton(
          leadingIcon: const Icon(Icons.person_outline_rounded, size: 20),
          onPressed: () => context.go('/profile'),
          child: const Text('Profile'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.receipt_long_outlined, size: 20),
          onPressed: () => context.go('/orders'),
          child: const Text('My orders'),
        ),
        if (phone && user.isAdmin)
          MenuItemButton(
            leadingIcon: const Icon(Icons.dashboard_customize_outlined, size: 20),
            onPressed: () => context.go('/admin'),
            child: const Text('Admin'),
          ),
        const Divider(height: AppSpacing.sm + 1),
        MenuItemButton(
          leadingIcon: const Icon(Icons.logout_rounded, size: 20),
          onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
          child: const Text('Log out'),
        ),
      ],
    );
  }
}
