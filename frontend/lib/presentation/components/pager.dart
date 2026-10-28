import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

class Pager extends StatelessWidget {
  final int page;
  final int pages;
  final int? total;
  final String? noun;
  final bool loading;
  final ValueChanged<int> onPage;

  const Pager({
    super.key,
    required this.page,
    required this.pages,
    this.total,
    this.noun,
    required this.loading,
    required this.onPage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = total != null && noun != null ? 'Page $page of $pages · $total $noun' : 'Page $page of $pages';
    final style = IconButton.styleFrom(
      side: BorderSide(color: scheme.outlineVariant),
      backgroundColor: scheme.surfaceContainerLowest,
      disabledBackgroundColor: Colors.transparent,
    );
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Previous page',
            style: style,
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            onPressed: loading || page <= 1 ? null : () => onPage(page - 1),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Next page',
            style: style,
            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
            onPressed: loading || page >= pages ? null : () => onPage(page + 1),
          ),
        ],
      ),
    );
  }
}
