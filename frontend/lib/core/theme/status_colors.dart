import 'package:flutter/material.dart';

class StatusTone {
  final Color fg;
  final Color bg;

  const StatusTone({required this.fg, required this.bg});

  static StatusTone lerp(StatusTone a, StatusTone b, double t) =>
      StatusTone(fg: Color.lerp(a.fg, b.fg, t)!, bg: Color.lerp(a.bg, b.bg, t)!);
}

class StatusColors extends ThemeExtension<StatusColors> {
  final StatusTone success;
  final StatusTone warning;
  final StatusTone danger;
  final StatusTone info;
  final StatusTone violet;
  final StatusTone neutral;

  const StatusColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.violet,
    required this.neutral,
  });

  static const light = StatusColors(
    success: StatusTone(fg: Color(0xFF1B5E20), bg: Color(0xFFE6F4EA)),
    warning: StatusTone(fg: Color(0xFF7A4300), bg: Color(0xFFFFF1DC)),
    danger: StatusTone(fg: Color(0xFFA8201A), bg: Color(0xFFFDE8E7)),
    info: StatusTone(fg: Color(0xFF0B4FB8), bg: Color(0xFFE7EFFD)),
    violet: StatusTone(fg: Color(0xFF5E2B97), bg: Color(0xFFF1E8FB)),
    neutral: StatusTone(fg: Color(0xFF3F4450), bg: Color(0xFFECEEF3)),
  );

  static const dark = StatusColors(
    success: StatusTone(fg: Color(0xFFA6E3B0), bg: Color(0xFF173A1F)),
    warning: StatusTone(fg: Color(0xFFFFD08A), bg: Color(0xFF3D2A06)),
    danger: StatusTone(fg: Color(0xFFFFB4AB), bg: Color(0xFF4C1512)),
    info: StatusTone(fg: Color(0xFFADC8FF), bg: Color(0xFF0F2B57)),
    violet: StatusTone(fg: Color(0xFFDCC2FF), bg: Color(0xFF36204F)),
    neutral: StatusTone(fg: Color(0xFFC8CCD6), bg: Color(0xFF2C3038)),
  );

  static StatusColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<StatusColors>() ?? (theme.brightness == Brightness.dark ? dark : light);
  }

  StatusTone stock(String stockStatus) => switch (stockStatus) {
    'low_stock' => warning,
    'out_of_stock' => danger,
    _ => success,
  };

  StatusTone order(String status) => switch (status) {
    'PENDING' => warning,
    'CONFIRMED' => info,
    'SHIPPED' => violet,
    'DELIVERED' => success,
    'CANCELLED' => danger,
    _ => neutral,
  };

  StatusTone payment(String paymentStatus) => switch (paymentStatus) {
    'PAID' => success,
    'UNPAID' => neutral,
    'REFUNDED' => neutral,
    _ => neutral,
  };

  @override
  StatusColors copyWith({
    StatusTone? success,
    StatusTone? warning,
    StatusTone? danger,
    StatusTone? info,
    StatusTone? violet,
    StatusTone? neutral,
  }) {
    return StatusColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      violet: violet ?? this.violet,
      neutral: neutral ?? this.neutral,
    );
  }

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) return this;
    return StatusColors(
      success: StatusTone.lerp(success, other.success, t),
      warning: StatusTone.lerp(warning, other.warning, t),
      danger: StatusTone.lerp(danger, other.danger, t),
      info: StatusTone.lerp(info, other.info, t),
      violet: StatusTone.lerp(violet, other.violet, t),
      neutral: StatusTone.lerp(neutral, other.neutral, t),
    );
  }
}
