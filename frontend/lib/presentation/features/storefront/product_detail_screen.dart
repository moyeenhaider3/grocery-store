import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_state.dart';
import '../../../bloc/cart/cart_bloc.dart';
import '../../../bloc/cart/cart_event.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../models/product_model.dart';
import '../../../repositories/catalog_repository.dart';
import '../../components/empty_state.dart';
import '../../components/error_state.dart';
import '../../components/loading_skeleton.dart';
import '../../components/page_container.dart';
import '../../components/price_text.dart';
import '../../components/product_thumbnail.dart';
import '../../components/page_header.dart';
import '../../components/stock_badge.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductModel? _product;
  bool _loading = true;
  bool _notFound = false;
  String? _error;

  CatalogRepository get _repo => sl<CatalogRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _notFound = false;
    });
    try {
      final product = await _repo.getStoreProduct(widget.productId);
      if (!mounted) return;
      setState(() {
        _product = product;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _notFound = e.statusCode == 404 || e.statusCode == 400;
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong';
        _loading = false;
      });
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _addToCart() {
    if (context.read<AuthBloc>().state.status != AuthStatus.authenticated) {
      context.go(Uri(path: '/login', queryParameters: {'from': '/products/${widget.productId}'}).toString());
      return;
    }
    context.read<CartBloc>().add(CartItemAdded(widget.productId));
  }

  Widget _addButton(ProductModel p, {bool compact = false}) {
    final outOfStock = p.stockStatus == 'out_of_stock';
    return Builder(builder: (context) {
      final busy = context.watch<CartBloc>().state.busyProductId == widget.productId;
      return FilledButton.icon(
        style: FilledButton.styleFrom(
          minimumSize: Size(64, compact ? AppSizes.buttonHeight : AppSizes.buttonHeightLarge),
        ),
        onPressed: outOfStock || busy ? null : _addToCart,
        icon: busy
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(outOfStock ? Icons.block_rounded : Icons.shopping_bag_outlined, size: 20),
        label: Text(outOfStock ? 'Out of stock' : 'Add to cart'),
      );
    });
  }

  Widget _perk(IconData icon, String text) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: scheme.surfaceContainer, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: scheme.onSurface),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _info(ProductModel p, {required bool showButton}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final phone = context.isPhone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(p.categoryName.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: scheme.secondary)),
        const SizedBox(height: AppSpacing.sm),
        Text(p.name, style: phone ? theme.textTheme.headlineMedium : theme.textTheme.displaySmall),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PriceText(p.price, size: phone ? PriceSize.lg : PriceSize.xl),
            StockBadge(stockStatus: p.stockStatus),
          ],
        ),
        if (showButton) ...[
          const SizedBox(height: AppSpacing.xl),
          SizedBox(width: double.infinity, child: _addButton(p)),
        ],
        const SizedBox(height: AppSpacing.xl),
        _perk(Icons.payments_outlined, 'Cash on delivery or instant demo payment'),
        _perk(Icons.inventory_2_outlined, 'Live stock, so what you see is what is available'),
        _perk(Icons.local_shipping_outlined, 'Track every order from My orders'),
        const SizedBox(height: AppSpacing.lg),
        const Divider(),
        const SizedBox(height: AppSpacing.xl),
        Text('Description', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        if (p.description.trim().isEmpty)
          Text('No description', style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant))
        else
          SelectableText(p.description, style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _breadcrumb(ProductModel p) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    return Row(
      children: [
        BackLink(label: 'Back to shop', onPressed: _back),
        if (!context.isPhone) ...[
          const SizedBox(width: AppSpacing.md),
          Text('Shop', style: muted),
          Icon(Icons.chevron_right_rounded, size: 16, color: scheme.onSurfaceVariant),
          Text(p.categoryName, style: muted),
          Icon(Icons.chevron_right_rounded, size: 16, color: scheme.onSurfaceVariant),
          Flexible(
            child: Text(
              p.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }

  Widget _body() {
    if (_loading) return const DetailSkeleton();
    if (_notFound) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'This product is not available',
        action: OutlinedButton(onPressed: () => context.go('/'), child: const Text('Back to shop')),
      );
    }
    final p = _product;
    if (_error != null || p == null) {
      return ErrorState(message: _error ?? 'Something went wrong', onRetry: _load);
    }
    final phone = context.isPhone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _breadcrumb(p),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 720) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: _ZoomableImage(product: p)),
                  SizedBox(width: constraints.maxWidth >= 1000 ? AppSpacing.huge - 16 : AppSpacing.xxl),
                  Expanded(flex: 5, child: _info(p, showButton: true)),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ZoomableImage(product: p),
                const SizedBox(height: AppSpacing.xl),
                _info(p, showButton: !phone),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _phoneBar(ProductModel p) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
        boxShadow: AppShadows.bar(scheme.brightness),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
          child: Row(
            children: [
              PriceText(p.price, size: PriceSize.lg),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: _addButton(p, compact: true)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _product;
    final page = PageContainer(child: _body());
    if (!context.isPhone || _loading || _error != null || p == null) return page;
    return Column(children: [Expanded(child: page), _phoneBar(p)]);
  }
}

/// Product image in a soft gallery frame. On pointer devices it zooms toward the cursor while
/// hovered, so shoppers can inspect detail without leaving the page.
class _ZoomableImage extends StatefulWidget {
  final ProductModel product;

  const _ZoomableImage({required this.product});

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  bool _zoom = false;
  Alignment _focus = Alignment.center;

  bool get _hasImage {
    final url = widget.product.imageUrl?.trim();
    if (url == null || url.isEmpty) return false;
    final scheme = Uri.tryParse(url)?.scheme;
    return scheme == 'http' || scheme == 'https';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final p = widget.product;
    final radius = BorderRadius.circular(AppRadius.xl);
    final canZoom = _hasImage && !context.isPhone;
    Widget image = ProductThumbnail(name: p.name, imageUrl: p.imageUrl, expand: true, borderRadius: BorderRadius.zero);
    image = AnimatedScale(
      scale: _zoom ? 1.9 : 1,
      alignment: _focus,
      duration: AppMotion.slow,
      curve: AppMotion.ease,
      child: image,
    );
    if (canZoom) {
      final scaled = image;
      image = MouseRegion(
        cursor: SystemMouseCursors.zoomIn,
        onEnter: (_) => setState(() => _zoom = true),
        onExit: (_) => setState(() {
          _zoom = false;
          _focus = Alignment.center;
        }),
        child: LayoutBuilder(
          builder: (context, constraints) => Listener(
            onPointerHover: (e) => setState(() {
              _focus = Alignment(
                (e.localPosition.dx / constraints.maxWidth) * 2 - 1,
                (e.localPosition.dy / constraints.maxHeight) * 2 - 1,
              );
            }),
            child: scaled,
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: radius,
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              image,
              if (canZoom)
                Positioned(
                  left: AppSpacing.lg,
                  bottom: AppSpacing.lg,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _zoom ? 0 : 1,
                      duration: AppMotion.base,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLowest.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in_rounded, size: 16, color: scheme.onSurface),
                            const SizedBox(width: 6),
                            Text('Hover to zoom', style: theme.textTheme.labelMedium),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
