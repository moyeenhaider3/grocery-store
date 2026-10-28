import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../../models/category_model.dart';
import '../../../../repositories/catalog_repository.dart';
import '../../../components/app_snack.dart';
import '../../../components/error_state.dart';
import '../../../components/loading_skeleton.dart';
import '../../../components/page_container.dart';
import '../../../components/page_header.dart';
import '../../../components/product_thumbnail.dart';
import '../../../components/section_card.dart';
import '../../../components/status_banner.dart';

/// Full-page product form. Create mode when productId == null, edit mode otherwise.
class ProductFormScreen extends StatefulWidget {
  final String? productId;

  const ProductFormScreen({super.key, this.productId});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  final _imageUrl = TextEditingController();
  bool _isActive = true;
  String? _categoryId;
  List<CategoryModel>? _categories;
  String? _loadError;
  String? _submitError;
  bool _submitting = false;

  bool get _isEdit => widget.productId != null;

  CatalogRepository get _repo => sl<CatalogRepository>();

  @override
  void initState() {
    super.initState();
    _name.addListener(_refresh);
    _imageUrl.addListener(_refresh);
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _stock.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final categories = await _repo.getCategories();
      if (_isEdit) {
        final p = await _repo.getProduct(widget.productId!);
        _name.text = p.name;
        _description.text = p.description;
        _price.text = paiseToRupeesInput(p.price);
        _stock.text = p.stock.toString();
        _imageUrl.text = p.imageUrl ?? '';
        _isActive = p.isActive;
        _categoryId = categories.any((c) => c.id == p.categoryId) ? p.categoryId : null;
      }
      if (!mounted) return;
      setState(() => _categories = categories);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'Something went wrong');
    }
  }

  String? _validateImageUrl(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    final uri = Uri.tryParse(v);
    final ok = uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
    return ok ? null : 'Image URL must be a web address (http or https)';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    final imageUrl = _imageUrl.text.trim();
    final body = <String, dynamic>{
      'name': _name.text.trim(),
      'description': _description.text.trim(),
      'price': rupeesToPaise(_price.text),
      'stock': int.parse(_stock.text.trim()),
      'category': _categoryId,
      'imageUrl': imageUrl.isEmpty ? null : imageUrl,
      'isActive': _isActive,
    };
    try {
      if (_isEdit) {
        await _repo.updateProduct(widget.productId!, body);
      } else {
        await _repo.createProduct(body);
      }
      if (!mounted) return;
      showAppSnack(context, _isEdit ? 'Product updated' : 'Product created');
      context.go('/admin/products');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitError = e.message;
        _submitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitError = 'Something went wrong';
        _submitting = false;
      });
    }
  }

  Widget _categoryField() {
    final categories = _categories!;
    if (categories.isEmpty) {
      return Row(
        children: [
          const Expanded(child: Text('Create a category first')),
          TextButton(onPressed: () => context.go('/admin/categories'), child: const Text('Go to categories')),
        ],
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: _categoryId,
      decoration: const InputDecoration(labelText: 'Category'),
      items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
      onChanged: (value) => setState(() => _categoryId = value),
      validator: (value) => value == null ? 'Choose a category' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = StatusColors.of(context);
    if (_loadError != null) return ErrorState(message: _loadError!, onRetry: _load);
    if (_categories == null) return const DetailSkeleton();
    final priceField = TextFormField(
      controller: _price,
      decoration: const InputDecoration(labelText: 'Price (₹)', hintText: '1299.00'),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) => rupeesToPaise(v ?? '') == null ? 'Enter a price above 0 with at most 2 decimals' : null,
    );
    final stockField = TextFormField(
      controller: _stock,
      decoration: const InputDecoration(labelText: 'Stock'),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (v) {
        final n = int.tryParse(v?.trim() ?? '');
        return n == null || n < 0 ? 'Enter a stock of 0 or more' : null;
      },
    );
    return PageContainer(
      maxWidth: AppWidths.form,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: _isEdit ? 'Edit product' : 'New product',
              backLabel: 'Products',
              onBack: () => context.go('/admin/products'),
            ),
            SectionCard(
              title: 'Details',
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Name'),
                    maxLength: 120,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _description,
                    decoration: const InputDecoration(labelText: 'Description (optional)'),
                    maxLength: 2000,
                    minLines: 3,
                    maxLines: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionCard(
              title: 'Pricing & stock',
              child: LayoutBuilder(
                builder: (context, c) => c.maxWidth >= 500
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: priceField),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: stockField),
                        ],
                      )
                    : Column(children: [priceField, const SizedBox(height: AppSpacing.md), stockField]),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionCard(
              title: 'Category & image',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _categoryField(),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _imageUrl,
                          decoration: const InputDecoration(labelText: 'Image URL (optional)'),
                          keyboardType: TextInputType.url,
                          validator: _validateImageUrl,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      ProductThumbnail(name: _name.text, imageUrl: _imageUrl.text, size: 96),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionCard(
              title: 'Visibility',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active (visible in the store)'),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                  if (_isEdit && !_isActive)
                    StatusBanner(
                      tone: colors.warning,
                      icon: Icons.visibility_off_outlined,
                      child: const Text('Inactive — hidden from the store'),
                    ),
                ],
              ),
            ),
            if (_submitError != null) ...[
              const SizedBox(height: AppSpacing.lg),
              StatusBanner(tone: colors.danger, icon: Icons.error_outline, child: Text(_submitError!)),
            ],
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _submitting ? null : () => context.go('/admin/products'),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: Text(_submitting ? 'Saving...' : 'Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
