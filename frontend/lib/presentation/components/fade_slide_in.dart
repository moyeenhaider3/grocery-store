import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// One-shot entrance: fades in while rising a few pixels. Respects "reduce motion".
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double offset;

  const FadeSlideIn({super.key, required this.child, this.delay = Duration.zero, this.offset = 12});

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: AppMotion.slow);
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: AppMotion.emphasized);

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _c.value = 1;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(offset: Offset(0, widget.offset * (1 - _t.value)), child: child),
      ),
    );
  }
}
