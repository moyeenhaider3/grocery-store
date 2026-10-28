import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Admin lists render as a table only when the list's CONTENT width (from a
/// LayoutBuilder, not the viewport) is at least this wide; otherwise as cards.
const double kAdminTableMinWidth = 840;

class AdminColumn {
  final String label;
  final int flex;

  const AdminColumn(this.label, {this.flex = 1});
}

/// One table row. Cell rules, followed by every screen using it:
/// - plain text cells use `maxLines: 1, overflow: TextOverflow.ellipsis`;
/// - pills and price cells are wrapped in
///   `FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft)` so they
///   shrink instead of overflowing.
/// Each cell is aligned centre-left so pills and buttons keep their intrinsic size.
class AdminTableRow extends StatelessWidget {
  final List<AdminColumn> columns;
  final List<Widget> cells;
  final VoidCallback? onTap;

  const AdminTableRow({super.key, required this.columns, required this.cells, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < columns.length; i++)
              Expanded(
                flex: columns[i].flex,
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Align(alignment: Alignment.centerLeft, child: cells[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A card with a column header row, then the given rows separated by dividers.
class AdminListCard extends StatelessWidget {
  final List<AdminColumn> columns;
  final List<Widget> rows;

  const AdminListCard({super.key, required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                for (final col in columns)
                  Expanded(
                    flex: col.flex,
                    child: Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: Text(
                        col.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            rows[i],
          ],
        ],
      ),
    );
  }
}
