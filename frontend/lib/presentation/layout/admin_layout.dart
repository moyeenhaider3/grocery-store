import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_tokens.dart';
import '../components/brand_mark.dart';

bool isAdminPath(String path) => path == '/admin' || path.startsWith('/admin/');

class _Dest {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;

  const _Dest(this.label, this.icon, this.selectedIcon, this.path);
}

const _destinations = [
  _Dest('Dashboard', Icons.dashboard_outlined, Icons.dashboard, '/admin'),
  _Dest('Orders', Icons.receipt_long_outlined, Icons.receipt_long, '/admin/orders'),
  _Dest('Products', Icons.inventory_2_outlined, Icons.inventory_2, '/admin/products'),
  _Dest('Categories', Icons.category_outlined, Icons.category, '/admin/categories'),
  _Dest('Users', Icons.people_outline, Icons.people, '/admin/users'),
];

int adminSelectedIndex(String path) {
  if (path == '/admin/orders' || path.startsWith('/admin/orders/')) return 1;
  if (path == '/admin/products' || path.startsWith('/admin/products/')) return 2;
  if (path == '/admin/categories' || path.startsWith('/admin/categories/')) return 3;
  if (path == '/admin/users' || path.startsWith('/admin/users/')) return 4;
  return 0;
}

/// Puts a navigation rail next to admin pages on tablet and desktop. Phones use [AdminDrawer].
class AdminLayout extends StatelessWidget {
  final String path;
  final Widget child;

  const AdminLayout({super.key, required this.path, required this.child});

  @override
  Widget build(BuildContext context) {
    if (context.isPhone) return child;
    final desktop = context.isDesktop;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NavigationRail(
          extended: desktop,
          minExtendedWidth: 232,
          labelType: desktop ? NavigationRailLabelType.none : NavigationRailLabelType.all,
          selectedIndex: adminSelectedIndex(path),
          onDestinationSelected: (i) => context.go(_destinations[i].path),
          destinations: [
            for (final d in _destinations)
              NavigationRailDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: Text(d.label)),
          ],
          trailing: Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: desktop
                    ? TextButton.icon(
                        onPressed: () => context.go('/'),
                        icon: const Icon(Icons.storefront_outlined),
                        label: const Text('Back to store'),
                      )
                    : IconButton(
                        tooltip: 'Back to store',
                        icon: const Icon(Icons.storefront_outlined),
                        onPressed: () => context.go('/'),
                      ),
              ),
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(child: child),
      ],
    );
  }
}

class AdminDrawer extends StatelessWidget {
  final String path;

  const AdminDrawer({super.key, required this.path});

  void _go(BuildContext context, String target) {
    Navigator.of(context).pop();
    context.go(target);
  }

  @override
  Widget build(BuildContext context) {
    final selected = adminSelectedIndex(path);
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  const BrandMark(),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Admin', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            for (var i = 0; i < _destinations.length; i++)
              ListTile(
                leading: Icon(i == selected ? _destinations[i].selectedIcon : _destinations[i].icon),
                title: Text(_destinations[i].label),
                selected: i == selected,
                onTap: () => _go(context, _destinations[i].path),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: const Text('Back to store'),
              onTap: () => _go(context, '/'),
            ),
          ],
        ),
      ),
    );
  }
}
