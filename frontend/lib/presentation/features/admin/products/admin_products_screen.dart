import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../models/category_model.dart';
import '../../../../models/product_model.dart';
import '../../../../repositories/catalog_repository.dart';
import '../../../components/admin_list.dart';
import '../../../components/empty_state.dart';
import '../../../components/error_state.dart';
import '../../../components/loading_skeleton.dart';
import '../../../components/page_container.dart';
import '../../../components/page_header.dart';
import '../../../components/pager.dart';
import '../../../components/price_text.dart';
import '../../../components/product_thumbnail.dart';
import '../../../components/status_pill.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final _searchController = TextEditingController();
  int _page = 1;
  String _q = '';
  String _status = 'all';
  String? _categoryId;
  List<CategoryModel> _categories = const [];
  ProductPage? _result;
  bool _loading = true;
  String? _error;

  CatalogRepository get _repo => sl<CatalogRepository>();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _repo.getCategories();
      if (!mounted) return;
      setState(() => _categories = categories);
    } catch (_) {
      // The filter just stays empty; the list load reports real errors.
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repo.getProducts(page: _page, q: _q, status: _status, categoryId: _categoryId);
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
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

  void _refilter() {
    _page = 1;
    _load();
  }

  void _goToPage(int page) {
    _page = page;
    _load();
  }

  Widget _toolbar() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: SizedBox(
                width: context.isPhone ? double.infinity : 280,
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search by name'),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) {
                    _q = value.trim();
                    _refilter();
                  },
                ),
              ),
            ),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all', label: Text('All')),
                ButtonSegment(value: 'active', label: Text('Active')),
                ButtonSegment(value: 'inactive', label: Text('Inactive')),
              ],
              selected: {_status},
              onSelectionChanged: (selection) {
                _status = selection.first;
                _refilter();
              },
            ),
            DropdownButton<String?>(
              value: _categoryId,
              hint: const Text('All categories'),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('All categories')),
                ..._categories.map((c) => DropdownMenuItem<String?>(value: c.id, child: Text(c.name))),
              ],
              onChanged: (value) {
                _categoryId = value;
                _refilter();
              },
            ),
          ],
        ),
      ),
    );
  }

  static const _columns = [
    AdminColumn('Product', flex: 4),
    AdminColumn('Category', flex: 2),
    AdminColumn('Price', flex: 2),
    AdminColumn('Stock', flex: 3),
    AdminColumn('Status', flex: 2),
  ];

  Widget _stockText(ProductModel p) {
    final theme = Theme.of(context);
    final colors = StatusColors.of(context);
    final lowOrOut = p.isLowOrOut;
    final suffix = p.stockStatus == 'out_of_stock' ? ' (out of stock)' : (lowOrOut ? ' (low)' : '');
    return Text(
      'Stock: ${p.stock}$suffix',
      maxLines: 2,
      style: lowOrOut
          ? theme.textTheme.bodyMedium?.copyWith(
              color: (p.stockStatus == 'out_of_stock' ? colors.danger : colors.warning).fg,
              fontWeight: FontWeight.w700,
            )
          : null,
    );
  }

  Widget _inactivePill() => StatusPill(label: 'Inactive', tone: StatusColors.of(context).neutral);

  Widget _tableRow(ProductModel p) {
    final colors = StatusColors.of(context);
    return Opacity(
      opacity: p.isActive ? 1 : 0.6,
      child: AdminTableRow(
        columns: _columns,
        onTap: () => context.go('/admin/products/${p.id}'),
        cells: [
          Row(
            children: [
              ProductThumbnail(name: p.name, imageUrl: p.imageUrl, size: 40),
              const SizedBox(width: AppSpacing.sm),
              Flexible(child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (!p.isActive) ...[const SizedBox(width: AppSpacing.sm), _inactivePill()],
            ],
          ),
          Text(p.categoryName, maxLines: 1, overflow: TextOverflow.ellipsis),
          FittedBox(fit: BoxFit.scaleDown, child: PriceText(p.price, size: PriceSize.sm)),
          _stockText(p),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: StatusPill(
              label: p.isActive ? 'Active' : 'Inactive',
              tone: p.isActive ? colors.success : colors.neutral,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(ProductModel p) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: p.isActive ? 1 : 0.6,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go('/admin/products/${p.id}'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProductThumbnail(name: p.name, imageUrl: p.imageUrl, size: 48),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: theme.textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                          Text(
                            p.categoryName,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    PriceText(p.price, size: PriceSize.sm),
                    _stockText(p),
                    if (!p.isActive) _inactivePill(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageContainer(
      scroll: false,
      child: LayoutBuilder(
        builder: (context, c) {
          final table = c.maxWidth >= kAdminTableMinWidth;
          final result = _result;
          final items = result?.items ?? const <ProductModel>[];
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: PageHeader(
                  title: 'Products',
                  actions: [
                    OutlinedButton.icon(
                      onPressed: () => context.go('/admin/products/import'),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Import CSV'),
                    ),
                    FilledButton.icon(
                      onPressed: () => context.go('/admin/products/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('New product'),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(child: _toolbar()),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
              if (_loading && result == null)
                const SliverToBoxAdapter(child: ListSkeleton(rows: 6))
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorState(message: _error!, onRetry: _load),
                )
              else if (items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(icon: Icons.inventory_2_outlined, title: 'No products match these filters.'),
                )
              else
                SliverOpacity(
                  opacity: _loading ? 0.5 : 1,
                  sliver: table
                      ? SliverToBoxAdapter(
                          child: AdminListCard(columns: _columns, rows: [for (final p in items) _tableRow(p)]),
                        )
                      : SliverList.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                          itemBuilder: (_, i) => _card(items[i]),
                        ),
                ),
              if (result != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Pager(
                      page: result.page,
                      pages: result.pages,
                      total: result.total,
                      noun: 'products',
                      loading: _loading,
                      onPage: _goToPage,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
