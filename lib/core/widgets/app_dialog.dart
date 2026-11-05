import 'package:flutter/material.dart';

import 'package:hammasir_driver/core/theme/app_palette.dart';
import 'package:hammasir_driver/core/widgets/status_chip.dart';

/// دیالوگ استاندارد برنامه: آیکون رنگی، عنوان، توضیح و دکمه‌های بزرگ.
/// با «تأیید» true و با «انصراف» یا بستن، false برمی‌گرداند.
Future<bool> showAppDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  Tone tone = Tone.brand,
  bool destructive = false,
  Widget? extra,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => _AppDialog(
      icon: icon,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      tone: tone,
      destructive: destructive,
      extra: extra,
    ),
  );
  return result ?? false;
}

class _AppDialog extends StatelessWidget {
  const _AppDialog({
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.tone,
    required this.destructive,
    this.cancelLabel,
    this.extra,
  });

  final IconData icon;
  final String title;
  final String message;
  final String confirmLabel;
  final String? cancelLabel;
  final Tone tone;
  final bool destructive;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final colors = toneColors(p, tone);

    return Dialog(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: colors.foreground),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: p.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.8, color: p.textMuted),
            ),
            if (extra != null) ...[
              const SizedBox(height: 14),
              extra!,
            ],
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: destructive ? p.danger : p.brand,
                foregroundColor: destructive ? Colors.white : p.onBrand,
              ),
              child: Text(confirmLabel),
            ),
            if (cancelLabel != null) ...[
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  foregroundColor: p.textMuted,
                ),
                child: Text(cancelLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
