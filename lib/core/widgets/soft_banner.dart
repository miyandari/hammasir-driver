import 'package:flutter/material.dart';

import 'package:hammasir_driver/core/theme/app_palette.dart';
import 'package:hammasir_driver/core/widgets/status_chip.dart';

/// نوار پیام رنگی (هشدار، خطا، اطلاع).
class SoftBanner extends StatelessWidget {
  const SoftBanner({
    super.key,
    required this.message,
    this.tone = Tone.warning,
    this.icon,
    this.action,
  });

  final String message;
  final Tone tone;
  final IconData? icon;

  /// دکمه‌ی اختیاری (مثل «تلاش دوباره»).
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = toneColors(context.palette, tone);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 20, color: colors.foreground),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.7,
                  color: colors.foreground,
                ),
              ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
