import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/web/browser_files.dart';
import '../../../../repositories/catalog_repository.dart';
import '../../../components/error_state.dart';
import '../../../components/loading_skeleton.dart';
import '../../../components/page_container.dart';
import '../../../components/page_header.dart';
import '../../../components/section_card.dart';
import '../../../components/status_banner.dart';

/// Bulk product import: template preview/download, then CSV upload.
class ProductImportScreen extends StatefulWidget {
  const ProductImportScreen({super.key});

  @override
  State<ProductImportScreen> createState() => _ProductImportScreenState();
}

class _ProductImportScreenState extends State<ProductImportScreen> {
  ImportTemplate? _template;
  String? _error;

  PickedTextFile? _file;
  bool _uploading = false;
  int? _created;
  String? _uploadError;
  List<Map<String, dynamic>> _rowErrors = const [];

  static const _guide = <(String, String)>[
    ('name', 'Required.'),
    ('description', 'Optional.'),
    ('price', 'Required. In rupees, like 1299.00. Above 0, at most 2 decimals.'),
    ('stock', 'Required. A whole number, 0 or more.'),
    ('category', 'Required. Must match one of the categories below; case does not matter. Categories are not created automatically.'),
    ('imageUrl', 'Optional. An http or https link.'),
    ('isActive', 'Optional. true or false. Defaults to true.'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final t = await sl<CatalogRepository>().getImportTemplate();
      if (!mounted) return;
      setState(() => _template = t);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Something went wrong');
    }
  }

  Future<void> _pick() async {
    try {
      final f = await pickTextFile();
      if (!mounted || f == null) return;
      setState(() {
        _file = f;
        _created = null;
        _uploadError = null;
        _rowErrors = const [];
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _file = null;
        _created = null;
        _rowErrors = const [];
        _uploadError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploadError = 'Something went wrong');
    }
  }

  Future<void> _upload() async {
    final f = _file;
    if (f == null) return;
    setState(() {
      _uploading = true;
      _created = null;
      _uploadError = null;
      _rowErrors = const [];
    });
    try {
      final n = await sl<CatalogRepository>().importProducts(f.text);
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _created = n;
        _file = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _uploadError = e.message;
        if (e.code == 'CSV_VALIDATION_FAILED' && e.details != null) {
          _rowErrors = e.details!.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _uploadError = 'Something went wrong';
      });
    }
  }

  Widget _uploadSection() {
    final f = _file;
    final colors = StatusColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _uploading ? null : _pick,
              icon: const Icon(Icons.attach_file),
              label: const Text('Choose CSV file'),
            ),
            if (f != null) Text('${f.name} (${(f.size / 1024).toStringAsFixed(1)} KB)'),
            FilledButton(
              onPressed: (f == null || _uploading) ? null : _upload,
              child: _uploading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Import'),
            ),
          ],
        ),
        if (_created != null) ...[
          const SizedBox(height: AppSpacing.md),
          StatusBanner(
            tone: colors.success,
            icon: Icons.check_circle_outline,
            action: TextButton(onPressed: () => context.go('/admin/products'), child: const Text('View products')),
            child: Text('Imported $_created products'),
          ),
        ],
        if (_uploadError != null) ...[
          const SizedBox(height: AppSpacing.md),
          StatusBanner(tone: colors.danger, icon: Icons.error_outline, child: Text(_uploadError!)),
        ],
        if (_rowErrors.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Row')),
                DataColumn(label: Text('Column')),
                DataColumn(label: Text('Message')),
              ],
              rows: [
                for (final e in _rowErrors)
                  DataRow(
                    cells: [
                      DataCell(Text('${e['row']}')),
                      DataCell(Text('${e['column']}')),
                      DataCell(Text('${e['message']}')),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageContainer(
      maxWidth: AppWidths.narrow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'Import products from CSV',
            backLabel: 'Back to products',
            onBack: () => context.go('/admin/products'),
          ),
          ..._templateSection(),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(title: '2. Upload', child: _uploadSection()),
        ],
      ),
    );
  }

  List<Widget> _templateSection() {
    final theme = Theme.of(context);
    if (_error != null) return [ErrorState(message: _error!, onRetry: _load)];
    final t = _template;
    if (t == null) return const [ListSkeleton(rows: 2)];
    return [
      SectionCard(
        title: '1. Template',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SelectableText(t.csv, style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace')),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: () => downloadTextFile('shopkart-products-template.csv', t.csv),
              icon: const Icon(Icons.download),
              label: const Text('Download template'),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      SectionCard(
        title: 'Columns',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (name, text) in _guide)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$name: ',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: text),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            const Text('Import only creates new products; it never updates existing ones.'),
            const Text('Max 500 rows and 1 MB.'),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      SectionCard(
        title: 'Valid categories',
        child: t.categories.isEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('No categories yet. Create a category first.'),
                  TextButton(onPressed: () => context.go('/admin/categories'), child: const Text('Go to categories')),
                ],
              )
            : Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [for (final c in t.categories) Chip(label: Text(c))],
              ),
      ),
    ];
  }
}
