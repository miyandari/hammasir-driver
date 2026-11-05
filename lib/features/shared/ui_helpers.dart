import 'package:flutter/material.dart';

import 'package:hammasir_driver/core/theme/app_palette.dart';
import 'package:hammasir_driver/core/widgets/app_dialog.dart';
import 'package:hammasir_driver/core/widgets/status_chip.dart';
import 'package:hammasir_driver/l10n/l10n.dart';

/// پیام کوتاه پایین صفحه با آیکون و رنگ.
void showMessage(
  BuildContext context,
  String message, {
  Tone tone = Tone.brand,
}) {
  final p = context.palette;
  final colors = toneColors(p, tone);
  final icon = switch (tone) {
    Tone.success => Icons.check_circle_rounded,
    Tone.danger => Icons.error_rounded,
    Tone.warning => Icons.info_rounded,
    _ => Icons.info_rounded,
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: p.text,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: Row(
          children: [
            Icon(icon, color: tone == Tone.brand ? p.surface : colors.foreground),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: TextStyle(color: p.surface)),
            ),
          ],
        ),
      ),
    );
}

/// پرسش تأیید (لغو رزرو، خروج، ...).
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  IconData icon = Icons.help_outline_rounded,
  Tone tone = Tone.warning,
  bool destructive = false,
}) {
  return showAppDialog(
    context,
    icon: icon,
    title: title,
    message: message,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel ?? context.t('common.cancel'),
    tone: tone,
    destructive: destructive,
  );
}

/// پیام موفقیت با یک دکمه.
Future<void> showSuccess(
  BuildContext context, {
  required String title,
  required String message,
  String? buttonLabel,
  Widget? extra,
}) async {
  await showAppDialog(
    context,
    icon: Icons.check_rounded,
    title: title,
    message: message,
    confirmLabel: buttonLabel ?? context.t('common.ok'),
    tone: Tone.success,
    extra: extra,
  );
}
