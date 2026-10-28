import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Product image with an initials-on-colour fallback (no URL, or the image fails to load).
/// With [expand] it fills the space it is given instead of using a fixed [size].
class ProductThumbnail extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final bool expand;
  final BorderRadius? borderRadius;

  const ProductThumbnail({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 48,
    this.expand = false,
    this.borderRadius,
  });

  String get _initials {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2);
    if (words.isEmpty) return '?';
    return words.map((w) => String.fromCharCode(w.runes.first)).join().toUpperCase();
  }

  Color get _color {
    var h = 0;
    for (final c in name.trim().toLowerCase().codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return HSLColor.fromAHSL(1, (h % 360).toDouble(), 0.45, 0.45).toColor();
  }

  Widget _fallback({double? width, double? height, required double fontBase}) {
    final base = _color;
    final deep = HSLColor.fromColor(base).withLightness(0.34).toColor();
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [base, deep]),
      ),
      foregroundDecoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.6, -0.7),
          radius: 1.1,
          colors: [Colors.white.withValues(alpha: 0.16), Colors.white.withValues(alpha: 0)],
        ),
      ),
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          // Large tiles get quieter initials so the fallback reads as artwork, not a shout.
          letterSpacing: fontBase > 120 ? fontBase * 0.01 : 0,
          fontSize: fontBase * (fontBase > 120 ? 0.18 : 0.36),
        ),
      ),
    );
  }

  /// Fades the decoded image in over the initials so images never pop in.
  Widget Function(BuildContext, Widget, int?, bool) _fadeIn(Widget Function() fallback) =>
      (context, child, frame, sync) {
        if (sync) return child;
        return Stack(
          fit: StackFit.expand,
          children: [
            fallback(),
            AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: AppMotion.slow,
              curve: AppMotion.ease,
              child: child,
            ),
          ],
        );
      };

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final scheme = url == null || url.isEmpty ? null : Uri.tryParse(url)?.scheme;
    final usable = scheme == 'http' || scheme == 'https';
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.sm);

    if (expand) {
      return ClipRRect(
        borderRadius: radius,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final m = math.min(constraints.maxWidth, constraints.maxHeight);
            final side = m.isFinite ? m : size;
            Widget fallback() => _fallback(fontBase: side);
            return SizedBox.expand(
              child: usable
                  ? Image.network(
                      url!,
                      fit: BoxFit.cover,
                      frameBuilder: _fadeIn(fallback),
                      errorBuilder: (_, _, _) => fallback(),
                      loadingBuilder: (context, child, progress) => progress == null ? child : fallback(),
                    )
                  : fallback(),
            );
          },
        ),
      );
    }

    Widget fallback() => _fallback(width: size, height: size, fontBase: size);
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: size,
        height: size,
        child: usable
            ? Image.network(
                url!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                frameBuilder: _fadeIn(fallback),
                errorBuilder: (_, _, _) => fallback(),
                loadingBuilder: (context, child, progress) => progress == null ? child : fallback(),
              )
            : fallback(),
      ),
    );
  }
}
