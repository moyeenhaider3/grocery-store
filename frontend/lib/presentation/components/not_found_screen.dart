import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_tokens.dart';
import 'brand_mark.dart';
import 'fade_slide_in.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: FadeSlideIn(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BrandMark(onTap: () => context.go('/')),
                  const SizedBox(height: AppSpacing.xxxl),
                  ExcludeSemantics(
                    child: Text(
                      '404',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -4,
                        color: scheme.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Page not found', style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    "The page you're looking for has moved or never existed.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(onPressed: () => context.go('/'), child: const Text('Go home')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
