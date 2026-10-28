import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/status_colors.dart';
import 'brand_mark.dart';
import 'empty_state.dart';
import 'fade_slide_in.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: Center(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final message = state.errorMessage;
            return FadeSlideIn(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BrandMark(large: true),
                      const SizedBox(height: AppSpacing.xxl),
                      if (message == null)
                        SizedBox(
                          width: 160,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: const LinearProgressIndicator(minHeight: 3),
                          ),
                        )
                      else ...[
                        EmblemIcon(
                          icon: Icons.cloud_off_rounded,
                          color: StatusColors.of(context).danger.fg,
                          background: StatusColors.of(context).danger.bg,
                          size: 72,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        FilledButton(
                          onPressed: () => context.read<AuthBloc>().add(AppStarted()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
