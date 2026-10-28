import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/status_colors.dart';
import '../../core/utils/date_format.dart';
import '../../models/order_model.dart';

class OrderTimeline extends StatelessWidget {
  final List<StatusEntry> history;

  const OrderTimeline({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = StatusColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < history.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 16,
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == history.length - 1 ? colors.order(history[i].status).fg : null,
                          border: i == history.length - 1
                              ? null
                              : Border.all(color: colors.order(history[i].status).fg, width: 2),
                        ),
                      ),
                      if (i != history.length - 1)
                        Expanded(child: Container(width: 2, color: theme.colorScheme.outlineVariant)),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: i == history.length - 1 ? 0 : AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(orderStatusLabel(history[i].status), style: theme.textTheme.titleSmall),
                        Text(
                          formatOrderDateTime(history[i].at),
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
