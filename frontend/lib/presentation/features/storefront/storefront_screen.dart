import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../models/category_model.dart';
import '../../../models/product_model.dart';
import '../../../repositories/catalog_repository.dart';
import '../../components/empty_state.dart';
import '../../components/error_state.dart';
import '../../components/loading_skeleton.dart';
import '../../components/brand_backdrop.dart';
import '../../components/fade_slide_in.dart';
import '../../components/pager.dart';
import 'product_card.dart';

class StorefrontScreen extends StatefulWidget {
  const StorefrontScreen({super.key});

  @override
  State<StorefrontScreen> createState() => _StorefrontScreenState();
}

class _StorefrontScreenState extends State<StorefrontScreen> {
  final _searchController = TextEditingController();
  final _scroll = ScrollController();
  final _heroKey = GlobalKey();
  bool _barPinned = false;
  Timer? _debounce;
  int _page = 1;
  int _requestSeq = 0;
  String _q = '';
  String _sort = 'newest';
  String? _categoryId;
  List<CategoryModel> _categories = const [];
  ProductPage? _result;
  bool _loading = true;
  String? _error;

  static const _sortLabels = {
    'newest': 'Newest',
    'price_asc': 'Price: low to high',
    'price_desc': 'Price: high to low',
  };

  CatalogRepository get _repo => sl<CatalogRepository>();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadCategories();
    _load();
  }

  double get _heroTop => context.isPhone ? AppSpacing.lg : AppSpacing.xl;

  /// Scroll offset at which the filter bar pins (hero plus its padding).
  double get _heroHeight {
    final h = _heroKey.currentContext?.size?.height;
    return h == null ? 0 : h + _heroTop + AppSpacing.sm;
  }

  void _onScroll() {
    final pinned = _scroll.hasClients && _heroHeight > 0 && _scroll.offset >= _heroHeight - 1;
    if (pinned != _barPinned) setState(() => _barPinned = pinned);
  }

  void _scrollToProducts() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      math.min(_heroHeight, _scroll.position.maxScrollExtent),
      duration: AppMotion.slow,
      curve: AppMotion.emphasized,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _repo.getStoreCategories();
      if (!mounted) return;
      setState(() => _categories = categories);
    } catch (_) {
      // Chip row stays hidden; the grid keeps working.
    }
  }

  void _refilter() {
    _page = 1;
    _load();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    setState(() {}); // refresh the clear button
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _q = value.trim();
      _refilter();
    });
  }

  Future<void> _load() async {
    final seq = ++_requestSeq;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repo.getStoreProducts(page: _page, q: _q, categoryId: _categoryId, sort: _sort);
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _error = 'Something went wrong';
        _loading = false;
      });
    }
  }

  void _goToPage(int page) {
    _page = page;
    _load();
  }

  void _setSort(String value) {
    _sort = value;
    _refilter();
  }

  Widget _searchField() {
    final scheme = Theme.of(context).colorScheme;
    final pill = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        prefixIcon: const Padding(
          padding: EdgeInsetsDirectional.only(start: 6),
          child: Icon(Icons.search_rounded),
        ),
        hintText: 'Search products',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: pill,
        enabledBorder: pill,
        focusedBorder: pill.copyWith(borderSide: BorderSide(color: scheme.primary, width: 1.6)),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : Padding(
                padding: const EdgeInsetsDirectional.only(end: 4),
                child: IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () {
                    _debounce?.cancel();
                    _searchController.clear();
                    _q = '';
                    _refilter();
                  },
                ),
              ),
      ),
      textInputAction: TextInputAction.search,
      onChanged: _onSearchChanged,
      onSubmitted: (value) {
        _debounce?.cancel();
        _q = value.trim();
        _refilter();
      },
    );
  }

  Widget _sortControl() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final phone = context.isPhone;
    return MenuAnchor(
      alignmentOffset: const Offset(0, 6),
      menuChildren: [
        for (final e in _sortLabels.entries)
          MenuItemButton(
            leadingIcon: Icon(e.key == _sort ? Icons.check_rounded : null, size: 18),
            onPressed: () => _setSort(e.key),
            child: Text(
              e.value,
              style: e.key == _sort ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700) : null,
            ),
          ),
      ],
      builder: (context, controller, _) {
        void toggle() => controller.isOpen ? controller.close() : controller.open();
        if (phone) {
          return IconButton(
            tooltip: 'Sort',
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48),
              backgroundColor: scheme.surfaceContainerLowest,
              side: BorderSide(color: scheme.outlineVariant),
            ),
            icon: const Icon(Icons.swap_vert_rounded),
            onPressed: toggle,
          );
        }
        return OutlinedButton.icon(
          onPressed: toggle,
          style: OutlinedButton.styleFrom(
            backgroundColor: scheme.surfaceContainerLowest,
            side: BorderSide(color: scheme.outlineVariant),
            padding: const EdgeInsets.only(left: 16, right: 12),
          ),
          icon: const Icon(Icons.swap_vert_rounded, size: 18),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sort: ', style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
              Text(_sortLabels[_sort]!),
              const SizedBox(width: 4),
              Icon(Icons.expand_more_rounded, size: 18, color: scheme.onSurfaceVariant),
            ],
          ),
        );
      },
    );
  }

  Widget _categoryStrip() {
    final scheme = Theme.of(context).colorScheme;
    Widget chip(String label, bool selected, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(label),
        labelStyle: TextStyle(color: selected ? scheme.onPrimary : scheme.onSurface),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
    return ShaderMask(
      // Soft fade on the right edge hints that the strip scrolls.
      shaderCallback: (rect) => LinearGradient(
        colors: [scheme.surface, scheme.surface, scheme.surface.withValues(alpha: 0)],
        stops: const [0, 0.92, 1],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: AppSpacing.xxl),
        child: Row(
          children: [
            chip('All', _categoryId == null, () {
              _categoryId = null;
              _refilter();
            }),
            for (final c in _categories)
              chip(c.name, _categoryId == c.id, () {
                _categoryId = c.id;
                _refilter();
              }),
          ],
        ),
      ),
    );
  }

  /// Horizontal inset that centres a [AppWidths.content] column in [width].
  double _side(double width) => math.max(context.gutter, (width - AppWidths.content) / 2 + context.gutter);

  Widget _filterBar() {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: AppMotion.base,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: _barPinned ? scheme.outlineVariant : scheme.surface.withValues(alpha: 0)),
        ),
        boxShadow: _barPinned
            ? [BoxShadow(color: scheme.shadow.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 8))]
            : null,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = _side(constraints.maxWidth);
          return FocusTraversalGroup(
            child: Padding(
              padding: EdgeInsets.fromLTRB(side, AppSpacing.md, side, AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: _searchField()),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _sortControl(),
                    ],
                  ),
                  if (_categories.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _categoryStrip(),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _hero() {
    final theme = Theme.of(context);
    final phone = context.isPhone;
    final desktop = context.isDesktop;
    final fg = BrandBackdrop.foreground(context);
    final muted = fg.withValues(alpha: 0.72);
    Widget perk(IconData icon, String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: fg.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: fg)),
        ],
      ),
    );
    return FadeSlideIn(
      child: BrandBackdrop(
        padding: EdgeInsets.symmetric(
          horizontal: phone ? AppSpacing.xl : AppSpacing.huge - 16,
          vertical: phone ? AppSpacing.xxl : AppSpacing.huge - 8,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'THE SHOPKART STORE',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Good things,\nthoughtfully picked.',
                style: (phone
                        ? theme.textTheme.headlineLarge
                        : desktop
                            ? theme.textTheme.displayMedium
                            : theme.textTheme.displaySmall)
                    ?.copyWith(color: fg),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Browse the full catalog, see live stock on every item, and pay in cash when your order arrives.',
                style: (phone ? theme.textTheme.bodyMedium : theme.textTheme.bodyLarge)?.copyWith(color: muted),
              ),
              const SizedBox(height: AppSpacing.xl),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: _scrollToProducts,
                    style: FilledButton.styleFrom(
                      backgroundColor: fg,
                      foregroundColor: theme.colorScheme.brightness == Brightness.dark
                          ? theme.colorScheme.surface
                          : theme.colorScheme.inverseSurface,
                    ),
                    icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                    label: const Text('Shop the catalog'),
                  ),
                  if (!phone) ...[
                    perk(Icons.payments_outlined, 'Cash on delivery'),
                    perk(Icons.inventory_2_outlined, 'Live stock'),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grid(List<ProductModel> items) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final g = ProductGridGeometry.of(constraints.crossAxisExtent);
        return SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (_, i) => FadeSlideIn(
              key: ValueKey(items[i].id),
              delay: Duration(milliseconds: 35 * math.min(i, 11)),
              child: ProductCard(product: items[i]),
            ),
            childCount: items.length,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: g.columns,
            crossAxisSpacing: g.spacing,
            mainAxisSpacing: g.spacing + AppSpacing.md,
            mainAxisExtent: g.tileHeight,
          ),
        );
      },
    );
  }

  Widget _resultLine(ProductPage result) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final category = _categories.where((c) => c.id == _categoryId).firstOrNull;
    final title = category?.name ?? (_q.isNotEmpty ? 'Search results' : 'All products');
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.isPhone ? theme.textTheme.titleLarge : theme.textTheme.headlineSmall,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              '${result.total} ${result.total == 1 ? 'item' : 'items'}',
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _bodySlivers() {
    final result = _result;
    if (_loading && result == null) {
      return [
        const SliverPadding(
          padding: EdgeInsets.only(top: AppSpacing.xl + 36),
          sliver: SliverToBoxAdapter(child: ProductGridSkeleton()),
        ),
      ];
    }
    if (_error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorState(message: _error!, onRetry: _load),
        ),
      ];
    }
    if (result == null || result.items.isEmpty) {
      final filtered = _q.isNotEmpty || _categoryId != null;
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: filtered ? Icons.search_off_rounded : Icons.inventory_2_outlined,
            title: filtered ? 'No products match your filters' : 'No products yet',
          ),
        ),
      ];
    }
    return [
      SliverToBoxAdapter(child: _resultLine(result)),
      SliverAnimatedOpacity(
        opacity: _loading ? 0.45 : 1,
        duration: AppMotion.fast,
        sliver: _grid(result.items),
      ),
    ];
  }

  /// Centres a sliver in the content column while the scroll view itself stays full-width, so the
  /// scrollbar sits at the window edge instead of floating beside the column.
  Widget _centered(Widget sliver, {double top = 0, double bottom = 0}) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final side = _side(constraints.crossAxisExtent);
        return SliverPadding(padding: EdgeInsets.fromLTRB(side, top, side, bottom), sliver: sliver);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return CustomScrollView(
      controller: _scroll,
      slivers: [
        _centered(
          SliverToBoxAdapter(child: KeyedSubtree(key: _heroKey, child: _hero())),
          top: _heroTop,
          bottom: AppSpacing.sm,
        ),
        PinnedHeaderSliver(child: _filterBar()),
        for (final sliver in _bodySlivers()) _centered(sliver),
        if (result != null && result.items.isNotEmpty)
          _centered(
            SliverToBoxAdapter(
              child: Pager(
                page: result.page,
                pages: result.pages,
                total: result.total,
                noun: 'products',
                loading: _loading,
                onPage: _goToPage,
              ),
            ),
            top: AppSpacing.xxxl,
            bottom: AppSpacing.huge,
          ),
      ],
    );
  }
}
