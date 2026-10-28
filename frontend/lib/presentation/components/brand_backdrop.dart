import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// The signature ink panel: a deep surface with two soft colour orbs and a fine ring that drift
/// slowly. Children get readable text and icon colours via [DefaultTextStyle] and [IconTheme].
class BrandBackdrop extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  const BrandBackdrop({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppRadius.xl)),
    this.padding = EdgeInsets.zero,
  });

  /// Text colour to use on the panel.
  static Color foreground(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return scheme.brightness == Brightness.dark ? scheme.onSurface : scheme.onInverseSurface;
  }

  @override
  State<BrandBackdrop> createState() => _BrandBackdropState();
}

class _BrandBackdropState extends State<BrandBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 18));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final bg = dark ? scheme.surfaceContainerHigh : scheme.inverseSurface;
    final fg = BrandBackdrop.foreground(context);
    final textTheme = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: CustomPaint(
        painter: _OrbPainter(
          dark: dark,
          animation: _c,
          background: bg,
          accent: scheme.secondary,
          sage: scheme.tertiary,
          ring: fg.withValues(alpha: 0.10),
        ),
        child: Padding(
          padding: widget.padding,
          child: Theme(
            data: Theme.of(context).copyWith(textTheme: textTheme.apply(bodyColor: fg, displayColor: fg)),
            child: IconTheme.merge(
              data: IconThemeData(color: fg),
              child: DefaultTextStyle.merge(style: TextStyle(color: fg), child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  final Animation<double> animation;
  final Color background;
  final Color accent;
  final Color sage;
  final Color ring;
  final bool dark;

  _OrbPainter({
    required this.dark,
    required this.animation,
    required this.background,
    required this.accent,
    required this.sage,
    required this.ring,
  }) : super(repaint: animation);

  void _orb(Canvas canvas, Offset c, double r, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final t = animation.value * 2 * math.pi;
    final w = size.width;
    final h = size.height;
    final unit = math.max(w, h);
    _orb(
      canvas,
      Offset(w * 0.86 + math.cos(t) * w * 0.03, h * 0.18 + math.sin(t) * h * 0.08),
      unit * 0.42,
      accent.withValues(alpha: dark ? 0.32 : 0.55),
    );
    _orb(
      canvas,
      Offset(w * 0.62 + math.sin(t) * w * 0.04, h * 1.05 + math.cos(t) * h * 0.06),
      unit * 0.36,
      sage.withValues(alpha: dark ? 0.28 : 0.45),
    );
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = ring;
    final ringCenter = Offset(w * 0.80, h * 0.55);
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(ringCenter, unit * (0.16 + i * 0.09) + math.sin(t + i) * 4, ringPaint);
    }
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.background != background || old.accent != accent || old.sage != sage || old.ring != ring;
}
