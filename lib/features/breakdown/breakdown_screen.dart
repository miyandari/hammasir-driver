import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hammasir_driver/app/stores.dart';
import 'package:hammasir_driver/core/location/location_service.dart';
import 'package:hammasir_driver/core/network/api_exception.dart';
import 'package:hammasir_driver/core/theme/app_palette.dart';
import 'package:hammasir_driver/core/widgets/choice_tile.dart';
import 'package:hammasir_driver/core/widgets/status_chip.dart';
import 'package:hammasir_driver/data/models/driver.dart';
import 'package:hammasir_driver/features/shared/page_header.dart';
import 'package:hammasir_driver/features/shared/ui_helpers.dart';
import 'package:hammasir_driver/l10n/l10n.dart';

/// اعلام خرابی: نوع خرابی، توضیح، «می‌توانم ادامه دهم؟» و موقعیت خودکار.
/// بدون اینترنت گزارش روی گوشی می‌ماند و بعداً خودکار ارسال می‌شود.
class BreakdownScreen extends StatefulWidget {
  const BreakdownScreen({super.key, required this.trip});

  final DriverTrip trip;

  @override
  State<BreakdownScreen> createState() => _BreakdownScreenState();
}

class _BreakdownScreenState extends State<BreakdownScreen> {
  final _note = TextEditingController();
  String _kind = breakdownKinds.first;
  bool _canContinue = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final stores = StoresScope.read(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    HapticFeedback.heavyImpact();

    // موقعیت: آخرین نقطه‌ی ردیابی، وگرنه یک نمونه‌ی تازه.
    double? lat = stores.tracking.lastFix?.lat;
    double? lng = stores.tracking.lastFix?.lng;
    if (lat == null) {
      final (_, point) = await LocationService.current();
      lat = point?.latitude;
      lng = point?.longitude;
    }

    final payload = <String, dynamic>{
      'kind': _kind,
      if (_note.text.trim().isNotEmpty) 'description': _note.text.trim(),
      'can_continue': _canContinue,
      if (lat != null && lng != null) 'latitude': lat,
      if (lat != null && lng != null) 'longitude': lng,
      'occurred_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      final queued = await stores.outbox.submit(widget.trip.id, payload);
      if (!mounted) return;
      Navigator.of(context).pop();
      showMessage(
        context,
        context.t(queued ? 'bd.queued' : 'bd.sent'),
        tone: queued ? Tone.warning : Tone.success,
      );
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

    return Scaffold(
      appBar: AppBar(title: Text(context.t('bd.title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          SectionTitle(context.t('bd.kind')),
          for (final kind in breakdownKinds)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ChoiceTile(
                title: context.t('bd.kind_$kind'),
                selected: _kind == kind,
                onTap: () => setState(() => _kind = kind),
              ),
            ),
          SectionTitle(context.t('bd.note')),
          TextField(
            controller: _note,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(hintText: context.t('bd.note_hint')),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _canContinue,
            onChanged: (v) => setState(() => _canContinue = v),
            title: Text(context.t('bd.can_continue')),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(_error!, style: TextStyle(color: p.danger)),
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _busy ? null : _submit,
            icon: const Icon(Icons.warning_amber_rounded),
            label: Text(context.t('bd.send')),
            style: FilledButton.styleFrom(
              backgroundColor: p.danger,
              minimumSize: const Size.fromHeight(54),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.t('bd.hint'),
            style: TextStyle(color: p.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
