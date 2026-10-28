import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// A rounded placeholder block with a gentle pulse.
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({super.key, this.width, required this.height, this.radius = AppRadius.sm});

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.55, end: 1).animate(_c),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

class ProductGridSkeleton extends StatelessWidget {
  final int count;

  const ProductGridSkeleton({super.key, this.count = 8});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.sizeOf(context).width;
        final g = ProductGridGeometry.of(w);
        final tile = g.tileWidth;
        return Wrap(
          spacing: g.spacing,
          runSpacing: g.spacing,
          children: [
            for (var i = 0; i < count; i++)
              SizedBox(
                width: tile,
                height: g.tileHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: tile, height: tile, radius: AppRadius.lg),
                    const SizedBox(height: AppSpacing.md + 2),
                    SkeletonBox(width: tile * 0.3, height: 10),
                    const SizedBox(height: AppSpacing.sm),
                    SkeletonBox(width: tile * 0.85, height: 14),
                    const SizedBox(height: AppSpacing.md),
                    SkeletonBox(width: tile * 0.35, height: 18),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class ListSkeleton extends StatelessWidget {
  final int rows;

  const ListSkeleton({super.key, this.rows = 3});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          const SkeletonBox(height: 104, radius: AppRadius.lg),
        ],
      ],
    );
  }
}

class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final bars = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SkeletonBox(width: 90, height: 10),
        SizedBox(height: AppSpacing.md),
        SkeletonBox(width: 280, height: 34),
        SizedBox(height: AppSpacing.md),
        SkeletonBox(width: 120, height: 20),
        SizedBox(height: AppSpacing.md),
        SkeletonBox(height: 16),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= AppBreakpoints.tablet;
        const image = SkeletonBox(height: 420, radius: AppRadius.xl);
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: image),
              const SizedBox(width: AppSpacing.xl),
              Expanded(child: bars),
            ],
          );
        }
        return Column(children: [image, const SizedBox(height: AppSpacing.lg), bars]);
      },
    );
  }
}
