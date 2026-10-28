import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'bloc/auth/auth_bloc.dart';
import 'bloc/auth/auth_event.dart';
import 'bloc/cart/cart_bloc.dart';
import 'core/di/injection_container.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final configError = apiConfigError(ApiClient.baseUrl);
  if (configError != null) {
    debugPrint(configError);
    runApp(
      MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        scrollBehavior: const AppScrollBehavior(),
        debugShowCheckedModeBanner: false,
        home: _ConfigErrorScreen(message: configError),
      ),
    );
    return;
  }

  usePathUrlStrategy();
  await initDependencies();
  runApp(const ShopKartApp());
}

class ShopKartApp extends StatelessWidget {
  const ShopKartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: sl<AuthBloc>()..add(AppStarted())),
        BlocProvider<CartBloc>.value(value: sl<CartBloc>()),
      ],
      child: MaterialApp.router(
        title: 'ShopKart',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        scrollBehavior: const AppScrollBehavior(),
        routerConfig: sl<AppRouter>().router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class _ConfigErrorScreen extends StatelessWidget {
  final String message;

  const _ConfigErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            margin: const EdgeInsets.all(AppSpacing.lg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.settings_suggest_outlined, size: 40, color: scheme.error),
                  const SizedBox(height: AppSpacing.md),
                  Text('Configuration error', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.md),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: SelectableText(
                      '--dart-define=API_BASE_URL=<your API URL>/api',
                      style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
