import 'package:flutter/material.dart';

/// رنگ‌های برند هم‌مسیر (روشن و تیره).
/// همه‌ی ویجت‌ها رنگ را از `context.palette` می‌گیرند، نه از کد رنگ ثابت.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brand,
    required this.brandDeep,
    required this.brandSoft,
    required this.onBrand,
    required this.accent,
    required this.background,
    required this.surface,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.dangerBorder,
  });

  final Color brand;
  final Color brandDeep;
  final Color brandSoft;
  final Color onBrand;
  final Color accent;
  final Color background;
  final Color surface;
  final Color border;
  final Color text;
  final Color textMuted;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color dangerBorder;

  static const AppPalette light = AppPalette(
    brand: Color(0xFF087F8C),
    brandDeep: Color(0xFF066570),
    brandSoft: Color(0xFFEAF6F7),
    onBrand: Color(0xFFFFFFFF),
    accent: Color(0xFFF2B84B),
    background: Color(0xFFF7F9FA),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFE3E8EA),
    text: Color(0xFF11262B),
    textMuted: Color(0xFF5B6B70),
    success: Color(0xFF146B49),
    successSoft: Color(0xFFE6F6EE),
    warning: Color(0xFF7A5214),
    warningSoft: Color(0xFFFFF4DC),
    danger: Color(0xFFC4412F),
    dangerSoft: Color(0xFFFDECE8),
    dangerBorder: Color(0xFFE9B8AF),
  );

  static const AppPalette dark = AppPalette(
    brand: Color(0xFF2FB3C2),
    brandDeep: Color(0xFF8FDCE5),
    brandSoft: Color(0xFF12353A),
    onBrand: Color(0xFF06262B),
    accent: Color(0xFFF2B84B),
    background: Color(0xFF0E1A1D),
    surface: Color(0xFF162428),
    border: Color(0xFF26373C),
    text: Color(0xFFE8F0F2),
    textMuted: Color(0xFF9FB2B7),
    success: Color(0xFF7FD6B0),
    successSoft: Color(0xFF12342A),
    warning: Color(0xFFF0C675),
    warningSoft: Color(0xFF3A2E10),
    danger: Color(0xFFF0A89C),
    dangerSoft: Color(0xFF3C1D18),
    dangerBorder: Color(0xFF6B3A32),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return t < 0.5 ? this : other;
  }
}

extension PaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
