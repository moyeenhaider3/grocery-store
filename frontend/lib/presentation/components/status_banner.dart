import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/status_colors.dart';

class StatusBanner extends StatelessWidget {
  final StatusTone tone;
  final IconData icon;
  final Widget child;
  final Widget? action;

  const StatusBanner({super.key, required this.tone, required this.icon, required this.child, this.action});

  @override
  Widget build(BuildContext context) {
    final body = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: tone.fg.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(icon, color: tone.fg, size: 18),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: DefaultTextStyle.merge(style: TextStyle(color: tone.fg), child: child),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md - 2),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: tone.fg.withValues(alpha: 0.18)),
      ),
      child: action == null
          ? body
          : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 420) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      body,
                      Padding(padding: const EdgeInsets.only(left: 44, top: AppSpacing.sm), child: action),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: body),
                    const SizedBox(width: AppSpacing.md),
                    action!,
                  ],
                );
              },
            ),
    );
  }
}
