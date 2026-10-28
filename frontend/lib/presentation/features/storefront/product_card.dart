import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/money.dart';
import '../../../models/product_model.dart';
import '../../components/price_text.dart';
import '../../components/product_thumbnail.dart';
import '../../components/stock_badge.dart';

/// Editorial product tile: a framed square image that lifts and slowly zooms on hover, then
/// category, name and price set beneath it. Stock is flagged on the image only when it matters
/// (low or out of stock); the full server status is always in the semantics label.
class ProductCard extends StatefulWidget {
  final ProductModel product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  void _open() => context.push('/products/${widget.product.id}');

  static const _greyscale = ColorFilter.matrix([
    0.45, 0.45, 0.10, 0, 0, //
    0.30, 0.60, 0.10, 0, 0, //
    0.30, 0.45, 0.25, 0, 0, //
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(AppRadius.lg);
    final outOfStock = p.stockStatus == 'out_of_stock';
    final showStock = p.stockStatus != 'in_stock';

    Widget image = ProductThumbnail(
      name: p.name,
      imageUrl: p.imageUrl,
      expand: true,
      borderRadius: BorderRadius.zero,
    );
    if (outOfStock) image = ColorFiltered(colorFilter: _greyscale, child: image);

    final frame = AnimatedContainer(
      duration: AppMotion.base,
      curve: AppMotion.ease,
      transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: radius,
        boxShadow: _hovered ? AppShadows.lifted(scheme.brightness) : null,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: _focused ? scheme.primary : scheme.onSurface.withValues(alpha: 0.06),
          width: _focused ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedScale(
                scale: _hovered ? 1.06 : 1,
                duration: AppMotion.image,
                curve: AppMotion.ease,
                child: image,
              ),
              if (showStock)
                Positioned(
                  left: AppSpacing.md,
                  top: AppSpacing.md,
                  child: StockBadge(stockStatus: p.stockStatus),
                ),
              Positioned(
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: AnimatedSlide(
                  offset: _hovered || _focused ? Offset.zero : const Offset(0, 0.4),
                  duration: AppMotion.base,
                  curve: AppMotion.ease,
                  child: AnimatedOpacity(
                    opacity: _hovered || _focused ? 1 : 0,
                    duration: AppMotion.base,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLowest,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.soft(scheme.brightness),
                      ),
                      child: Icon(Icons.arrow_outward_rounded, size: 20, color: scheme.onSurface),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final info = SizedBox(
      height: ProductGridGeometry.infoHeight,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md + 2, left: 2, right: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              p.categoryName.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xs + 2),
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: AppMotion.fast,
                style: (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
                  color: scheme.onSurface,
                  decoration: _hovered ? TextDecoration.underline : TextDecoration.none,
                  decorationColor: scheme.onSurface.withValues(alpha: 0.4),
                ),
                child: Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ),
            const Spacer(),
            PriceText(
              p.price,
              size: PriceSize.md,
              color: outOfStock ? scheme.onSurfaceVariant : null,
            ),
          ],
        ),
      ),
    );

    return Semantics(
      button: true,
      label: '${p.name}, ${formatPaise(p.price)}, ${stockStatusLabel(p.stockStatus)}',
      excludeSemantics: true,
      onTap: _open,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => _open())},
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        child: GestureDetector(
          onTap: _open,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          behavior: HitTestBehavior.opaque,
          child: AnimatedScale(
            scale: _pressed ? 0.98 : 1,
            duration: AppMotion.fast,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [frame, info],
            ),
          ),
        ),
      ),
    );
  }
}
