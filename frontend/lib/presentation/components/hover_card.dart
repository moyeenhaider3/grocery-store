import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// A tappable "paper" surface: hairline border, lifts with a soft shadow on hover, shows a
/// focus ring for keyboard users and an ink ripple on press.
class HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;
  final String? semanticLabel;

  const HoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadius.lg,
    this.borderColor,
    this.semanticLabel,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final b = scheme.brightness;
    final interactive = widget.onTap != null;
    final lifted = interactive && _hovered;
    final radius = BorderRadius.circular(widget.radius);
    final borderColor = _focused
        ? scheme.primary
        : widget.borderColor ?? (lifted ? scheme.outline.withValues(alpha: 0.45) : scheme.outlineVariant);

    final card = AnimatedContainer(
      duration: AppMotion.base,
      curve: AppMotion.ease,
      transform: Matrix4.translationValues(0, lifted ? -2 : 0, 0),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: radius,
        border: Border.all(color: borderColor, width: _focused ? 2 : 1),
        boxShadow: lifted ? AppShadows.lifted(b) : AppShadows.soft(b),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: radius,
          onHover: interactive ? (h) => setState(() => _hovered = h) : null,
          onFocusChange: interactive ? (f) => setState(() => _focused = f) : null,
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );
    if (widget.semanticLabel == null) return card;
    return Semantics(button: interactive, label: widget.semanticLabel, child: card);
  }
}
