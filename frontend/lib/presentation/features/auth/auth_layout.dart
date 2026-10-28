import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../components/brand_backdrop.dart';
import '../../components/brand_mark.dart';
import '../../components/fade_slide_in.dart';

class AuthLayout extends StatelessWidget {
  final Widget child;

  const AuthLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Widget card;
    if (context.isDesktop) {
      card = ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl + 4),
            boxShadow: AppShadows.lifted(scheme.brightness),
          ),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl + 4)),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 11,
                      child: BrandBackdrop(
                        padding: const EdgeInsets.all(AppSpacing.xxxl),
                        child: const _BrandPanel(),
                      ),
                    ),
                    Expanded(
                      flex: 10,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl, vertical: AppSpacing.huge - 16),
                        child: Center(child: child),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      card = ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppWidths.auth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.soft(scheme.brightness),
          ),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
            child: Padding(
              padding: EdgeInsets.all(context.isPhone ? AppSpacing.xl : AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: BrandMark(onTap: () => context.go('/')),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  child,
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(context.isPhone ? AppSpacing.md : AppSpacing.xl),
            child: FadeSlideIn(child: card),
          ),
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = BrandBackdrop.foreground(context);
    Widget row(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: fg.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: fg.withValues(alpha: 0.14)),
                ),
                child: Icon(icon, color: fg, size: 18),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: fg.withValues(alpha: 0.85))),
              ),
            ],
          ),
        );
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandMark(inverse: true, onTap: () => context.go('/')),
        const SizedBox(height: AppSpacing.huge),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Everything you need, delivered.', style: theme.textTheme.displaySmall?.copyWith(color: fg)),
            const SizedBox(height: AppSpacing.xl),
            row(Icons.local_shipping_outlined, 'Cash on delivery or demo payment'),
            row(Icons.inventory_2_outlined, 'Live stock, server-checked prices'),
            row(Icons.receipt_long_outlined, 'Track every order'),
          ],
        ),
      ],
    );
  }
}
