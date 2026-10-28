import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../presentation/components/not_found_screen.dart';
import '../../presentation/components/splash_screen.dart';
import '../../presentation/features/admin/admin_screen.dart';
import '../../presentation/features/admin/categories/admin_categories_screen.dart';
import '../../presentation/features/admin/orders/admin_order_detail_screen.dart';
import '../../presentation/features/admin/orders/admin_orders_screen.dart';
import '../../presentation/features/admin/products/admin_products_screen.dart';
import '../../presentation/features/admin/users/admin_users_screen.dart';
import '../../presentation/features/admin/products/product_form_screen.dart';
import '../../presentation/features/admin/products/product_import_screen.dart';
import '../../presentation/features/auth/login_screen.dart';
import '../../presentation/features/cart/cart_screen.dart';
import '../../presentation/features/checkout/checkout_screen.dart';
import '../../presentation/features/orders/order_detail_screen.dart';
import '../../presentation/features/orders/orders_screen.dart';
import '../../presentation/features/auth/signup_screen.dart';
import '../../presentation/features/profile/profile_screen.dart';
import '../../presentation/features/storefront/product_detail_screen.dart';
import '../../presentation/features/storefront/storefront_screen.dart';
import '../../presentation/layout/app_shell.dart';

class AppRouter {
  final AuthBloc authBloc;
  late final StreamSubscription<AuthState> _sessionSub;

  AppRouter(this.authBloc) {
    // Session end: authenticated -> unauthenticated.
    var previous = authBloc.state;
    _sessionSub = authBloc.stream.listen((current) {
      if (previous.status == AuthStatus.authenticated && current.status == AuthStatus.unauthenticated) {
        final location = router.routerDelegate.currentConfiguration.uri;
        if (current.sessionExpired && !_isPublicPath(location.path)) {
          router.go(Uri(path: '/login', queryParameters: {'from': location.toString()}).toString());
        } else {
          router.go('/login');
        }
      }
      previous = current;
    });
  }

  void dispose() {
    _sessionSub.cancel();
  }

  static const _publicPaths = {'/', '/login', '/signup'};

  static bool _isPublicPath(String path) => _publicPaths.contains(path) || path.startsWith('/products/');

  /// Only same-app paths are honoured as post-login targets (no open redirect).
  static String? _safeFrom(String? from) {
    if (from != null && from.startsWith('/') && !from.startsWith('//')) return from;
    return null;
  }

  static Page<void> _page(GoRouterState state, Widget child) => NoTransitionPage(key: state.pageKey, child: child);

  String? _redirect(AuthState auth, Uri uri) {
    final path = uri.path;
    final from = _safeFrom(uri.queryParameters['from']);

    if (auth.status == AuthStatus.unknown) {
      if (path == '/splash') return null;
      return Uri(path: '/splash', queryParameters: {'from': uri.toString()}).toString();
    }

    final authed = auth.status == AuthStatus.authenticated;

    if (path == '/splash') {
      if (!authed && auth.sessionExpired) return '/login';
      return from ?? '/';
    }

    if (!authed && !_isPublicPath(path)) {
      return Uri(path: '/login', queryParameters: {'from': uri.toString()}).toString();
    }

    if (authed && (path == '/login' || path == '/signup')) return from ?? '/';

    // role-gated paths
    // Cosmetic only: the API enforces admin access.
    if (authed && (path == '/admin' || path.startsWith('/admin/')) && auth.user?.isAdmin != true) return '/';

    return null;
  }

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) => _redirect(authBloc.state, state.uri),
    errorPageBuilder: (context, state) => _page(state, const NotFoundScreen()),
    routes: [
      GoRoute(path: '/splash', pageBuilder: (context, state) => _page(state, const SplashScreen())),
      GoRoute(path: '/login', pageBuilder: (context, state) => _page(state, const LoginScreen())),
      GoRoute(path: '/signup', pageBuilder: (context, state) => _page(state, const SignupScreen())),
      ShellRoute(
        pageBuilder: (context, state, child) => _page(state, AppShell(child: child)),
        routes: [
          GoRoute(path: '/', pageBuilder: (context, state) => _page(state, const StorefrontScreen())),
          GoRoute(
            path: '/products/:id',
            name: 'product-detail',
            pageBuilder: (context, state) =>
                _page(state, ProductDetailScreen(productId: state.pathParameters['id']!)),
          ),
          GoRoute(path: '/cart', name: 'cart', pageBuilder: (context, state) => _page(state, const CartScreen())),
          GoRoute(
            path: '/checkout',
            name: 'checkout',
            pageBuilder: (context, state) => _page(state, const CheckoutScreen()),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) => _page(state, const ProfileScreen()),
          ),
          GoRoute(path: '/orders', name: 'orders', pageBuilder: (context, state) => _page(state, const OrdersScreen())),
          GoRoute(
            path: '/orders/:id',
            name: 'order-detail',
            pageBuilder: (context, state) => _page(
              state,
              OrderDetailScreen(
                orderId: state.pathParameters['id']!,
                justPlaced: state.uri.queryParameters['placed'] == '1',
              ),
            ),
          ),
          GoRoute(path: '/admin', name: 'admin', pageBuilder: (context, state) => _page(state, const AdminScreen())),
          GoRoute(
            path: '/admin/orders',
            name: 'admin-orders',
            pageBuilder: (context, state) => _page(state, const AdminOrdersScreen()),
          ),
          GoRoute(
            path: '/admin/orders/:id',
            name: 'admin-order-detail',
            pageBuilder: (context, state) =>
                _page(state, AdminOrderDetailScreen(orderId: state.pathParameters['id']!)),
          ),
          GoRoute(
            path: '/admin/users',
            name: 'admin-users',
            pageBuilder: (context, state) => _page(state, const AdminUsersScreen()),
          ),
          GoRoute(
            path: '/admin/categories',
            name: 'admin-categories',
            pageBuilder: (context, state) => _page(state, const AdminCategoriesScreen()),
          ),
          GoRoute(
            path: '/admin/products',
            name: 'admin-products',
            pageBuilder: (context, state) => _page(state, const AdminProductsScreen()),
          ),
          GoRoute(
            path: '/admin/products/new',
            name: 'admin-product-new',
            pageBuilder: (context, state) => _page(state, const ProductFormScreen()),
          ),
          GoRoute(
            path: '/admin/products/import',
            name: 'admin-product-import',
            pageBuilder: (context, state) => _page(state, const ProductImportScreen()),
          ),
          GoRoute(
            path: '/admin/products/:id',
            name: 'admin-product-edit',
            pageBuilder: (context, state) =>
                _page(state, ProductFormScreen(productId: state.pathParameters['id'])),
          ),
        ],
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
