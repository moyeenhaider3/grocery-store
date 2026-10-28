import 'package:flutter/material.dart';

import '../../core/theme/status_colors.dart';
import 'status_pill.dart';

String stockStatusLabel(String stockStatus) => switch (stockStatus) {
  'low_stock' => 'Low stock',
  'out_of_stock' => 'Out of stock',
  _ => 'In stock',
};

/// Shows the server-computed stock status. The app never compares stock numbers itself.
class StockBadge extends StatelessWidget {
  final String stockStatus;

  const StockBadge({super.key, required this.stockStatus});

  @override
  Widget build(BuildContext context) {
    return StatusPill(label: stockStatusLabel(stockStatus), tone: StatusColors.of(context).stock(stockStatus));
  }
}
