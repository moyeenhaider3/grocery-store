import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../models/category_model.dart';
import '../../../../repositories/catalog_repository.dart';
import '../../../components/app_snack.dart';
import '../../../components/confirm_dialog.dart';
import '../../../components/empty_state.dart';
import '../../../components/error_state.dart';
import '../../../components/loading_skeleton.dart';
import '../../../components/page_container.dart';
import '../../../components/page_header.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  List<CategoryModel>? _categories;
  String? _error;
  bool _loading = true;

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
    });
    try {
      final categories = await _repo.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
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

  // Shared add / rename dialog: one field, server errors shown under it.
  Future<void> _showNameDialog({CategoryModel? existing}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _NameDialog(existing: existing),
    );
    if (saved == true && mounted) {
      showAppSnack(context, existing == null ? 'Category created' : 'Category renamed');
      await _load();
    }
  }

  Future<void> _confirmDelete(CategoryModel category) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete "${category.name}"?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    try {
      await _repo.deleteCategory(category.id);
      if (!mounted) return;
      showAppSnack(context, 'Category deleted');
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppSnack(context, e.message);
    } catch (_) {
      if (!mounted) return;
      showAppSnack(context, 'Something went wrong');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _categories ?? const <CategoryModel>[];
    return PageContainer(
      maxWidth: AppWidths.form,
      scroll: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PageHeader(
              title: 'Categories',
              actions: [
                FilledButton.icon(
                  onPressed: () => _showNameDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add category'),
                ),
              ],
            ),
          ),
          if (_loading)
            const SliverToBoxAdapter(child: ListSkeleton(rows: 4))
          else if (_error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorState(message: _error!, onRetry: _load),
            )
          else if (categories.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.category_outlined,
                title: 'No categories yet. Add one to start building the catalog.',
              ),
            )
          else
            SliverToBoxAdapter(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < categories.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      _row(theme, categories[i]),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(ThemeData theme, CategoryModel c) {
    final count = '${c.productCount} ${c.productCount == 1 ? 'product' : 'products'}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(count, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Rename',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showNameDialog(existing: c),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(c),
          ),
        ],
      ),
    );
  }
}

class _NameDialog extends StatefulWidget {
  final CategoryModel? existing;
  const _NameDialog({this.existing});

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(text: widget.existing?.name ?? '');
  bool _saving = false;
  String? _serverError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _serverError = null;
    });
    final repo = sl<CatalogRepository>();
    final name = _controller.text.trim();
    try {
      if (widget.existing == null) {
        await repo.createCategory(name);
      } else {
        await repo.renameCategory(widget.existing!.id, name);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _serverError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _serverError = 'Something went wrong';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add category' : 'Rename category'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLength: 50,
          decoration: InputDecoration(labelText: 'Category name', errorText: _serverError),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Category name is required' : null,
          onFieldSubmitted: (_) => _saving ? null : _save(),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: _saving ? null : _save, child: const Text('Save')),
      ],
    );
  }
}
