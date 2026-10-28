import 'package:flutter/material.dart';

import '../../core/utils/money.dart';

enum PriceSize { sm, md, lg, xl }

/// Only formats a server-provided amount in paise; never computes prices.
class PriceText extends StatelessWidget {
  final int paise;
  final PriceSize size;
  final Color? color;

  const PriceText(this.paise, {super.key, this.size = PriceSize.md, this.color});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final base = switch (size) {
      PriceSize.sm => t.titleSmall,
      PriceSize.md => t.titleMedium,
      PriceSize.lg => t.headlineSmall,
      PriceSize.xl => t.headlineLarge,
    };
    return Text(
      formatPaise(paise),
      style: base?.copyWith(
        fontWeight: size == PriceSize.xl ? FontWeight.w800 : FontWeight.w700,
        letterSpacing: size.index >= PriceSize.lg.index ? -0.6 : -0.1,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
