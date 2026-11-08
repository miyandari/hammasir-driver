import 'package:flutter/material.dart';

import 'package:hammasir_driver/app/deps.dart';
import 'package:hammasir_driver/core/network/api_exception.dart';
import 'package:hammasir_driver/core/theme/app_palette.dart';
import 'package:hammasir_driver/core/utils/persian.dart';
import 'package:hammasir_driver/core/widgets/status_chip.dart';
import 'package:hammasir_driver/features/shared/ui_helpers.dart';
import 'package:hammasir_driver/l10n/l10n.dart';

const List<int> _delayChoices = [5, 10, 15, 30, 45, 60];

/// اعلام تأخیر: چند دقیقه + دلیل اختیاری. دانشجویان رزروکننده مطلع می‌شوند.
Future<void> showDelaySheet(BuildContext context, int tripId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _DelaySheet(tripId: tripId, parent: context),
    ),
  );
}

class _DelaySheet extends StatefulWidget {
  const _DelaySheet({required this.tripId, required this.parent});

  final int tripId;
  final BuildContext parent;

  @override
  State<_DelaySheet> createState() => _DelaySheetState();
}

class _DelaySheetState extends State<_DelaySheet> {
  final _reason = TextEditingController();
  int _minutes = 10;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final deps = DepsScope.read(context);
    final parent = widget.parent;
    final message = context.t('delay.sent');
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await deps.driver.reportDelay(widget.tripId, _minutes, _reason.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      if (parent.mounted) showMessage(parent, message, tone: Tone.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.t('delay.title'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in _delayChoices)
                  ChoiceChip(
                    label: Text(context.t('delay.minutes', {'n': Fa.digits(m)})),
                    selected: _minutes == m,
                    onSelected: (_) => setState(() => _minutes = m),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reason,
              maxLength: 200,
              decoration: InputDecoration(hintText: context.t('delay.reason_hint')),
            ),
            if (_error != null) Text(_error!, style: TextStyle(color: p.danger)),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _busy ? null : _send,
              icon: const Icon(Icons.schedule_rounded),
              label: Text(context.t('delay.send')),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
          ],
        ),
      ),
    );
  }
}
