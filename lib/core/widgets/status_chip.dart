import 'package:flutter/material.dart';

import 'package:hammasir_driver/core/theme/app_palette.dart';

enum Tone { brand, success, warning, danger, neutral }

/// رنگ پس‌زمینه و متن برای هر Tone.
({Color background, Color foreground}) toneColors(AppPalette p, Tone tone) {
  switch (tone) {
    case Tone.brand:
      return (background: p.brandSoft, foreground: p.brandDeep);
    case Tone.success:
      return (background: p.successSoft, foreground: p.success);
    case Tone.warning:
      return (background: p.warningSoft, foreground: p.warning);
    case Tone.danger:
      return (background: p.dangerSoft, foreground: p.danger);
    case Tone.neutral:
      return (background: p.border, foreground: p.textMuted);
  }
}

/// برچسب کوچک وضعیت (تأیید شده، لیست انتظار، ...).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.tone});

  final String label;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final colors = toneColors(context.palette, tone);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: colors.foreground,
        ),
      ),
    );
  }
}
