import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import 'fade_slide_in.dart';

/// Caps content width, centres it and applies responsive page padding.
///
/// The scroll view always spans the full width so its scrollbar sits at the window edge; only the
/// content inside it is capped. The content fades in once when the page opens.
class PageContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final bool scroll;
  final EdgeInsetsGeometry? padding;

  const PageContainer({
    super.key,
    required this.child,
    this.maxWidth = AppWidths.content,
    this.scroll = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final padded = Padding(padding: padding ?? context.pagePadding, child: child);
    final capped = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: FadeSlideIn(child: padded),
      ),
    );
    return scroll ? SingleChildScrollView(child: capped) : capped;
  }
}
