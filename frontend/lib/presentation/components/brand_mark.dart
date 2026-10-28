import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import 'brand_backdrop.dart';

/// Logo: an ink tile with a bag glyph and a persimmon dot, followed by the "ShopKart." wordmark.
/// Use [inverse] when it sits on a [BrandBackdrop].
class BrandMark extends StatelessWidget {
  final bool large;
  final bool inverse;
  final VoidCallback? onTap;

  const BrandMark({super.key, this.large = false, this.inverse = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final box = large ? 52.0 : 34.0;
    final ink = inverse ? BrandBackdrop.foreground(context) : scheme.primary;
    final panel = scheme.brightness == Brightness.dark ? scheme.surfaceContainerHigh : scheme.inverseSurface;
    final onInk = inverse ? panel : scheme.onPrimary;
    final style = (large ? theme.textTheme.headlineMedium : theme.textTheme.titleLarge)?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: large ? -1 : -0.6,
      color: ink,
    );
    final mark = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: box,
            height: box,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(box * 0.3)),
                    child: Icon(Icons.shopping_bag_outlined, color: onInk, size: box * 0.56),
                  ),
                ),
                Positioned(
                  right: -box * 0.08,
                  top: -box * 0.08,
                  child: Container(
                    width: box * 0.3,
                    height: box * 0.3,
                    decoration: BoxDecoration(
                      color: scheme.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: inverse ? panel : scheme.surface, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: large ? AppSpacing.md : AppSpacing.sm + 2),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'ShopKart'),
                TextSpan(text: '.', style: TextStyle(color: scheme.secondary)),
              ],
            ),
            style: style,
          ),
        ],
      ),
    );
    if (onTap == null) return mark;
    return Semantics(
      button: true,
      label: 'ShopKart home',
      child: ExcludeSemantics(
        child: InkWell(borderRadius: BorderRadius.circular(AppRadius.md), onTap: onTap, child: mark),
      ),
    );
  }
}
