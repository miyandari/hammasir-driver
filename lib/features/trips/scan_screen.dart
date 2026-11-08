import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:hammasir_driver/app/deps.dart';
import 'package:hammasir_driver/core/network/api_exception.dart';
import 'package:hammasir_driver/core/theme/app_palette.dart';
import 'package:hammasir_driver/core/utils/persian.dart';
import 'package:hammasir_driver/core/widgets/app_dialog.dart';
import 'package:hammasir_driver/core/widgets/status_chip.dart';
import 'package:hammasir_driver/data/models/driver.dart';
import 'package:hammasir_driver/features/shared/ui_helpers.dart';
import 'package:hammasir_driver/l10n/l10n.dart';

/// اسکن پیاپی QR دانشجویان هنگام سوار شدن.
///
/// - رزروداران بی‌صدا ثبت می‌شوند (فقط یک لرزش کوتاه و شمارنده‌ی بالای صفحه).
/// - تکراری‌ها نادیده گرفته می‌شوند.
/// - بدون رزرو: فقط با تأیید راننده به لیست مسافران اضافه می‌شود.
/// - اسکن بعدی بدون هیچ مرحله‌ی اضافه ادامه پیدا می‌کند.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, required this.tripId});

  final int tripId;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _scanner = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 500,
  );
  late final Deps _deps = DepsScope.read(context);

  /// آخرین زمان پردازش هر QR؛ جلوی اسکن پشت‌سرهم یک کد را می‌گیرد.
  final Map<String, DateTime> _seen = {};
  final Queue<String> _queue = Queue();
  bool _working = false;
  int _count = 0;
  bool _flash = false;
  bool _torch = false;

  static const _repeatGap = Duration(seconds: 5);
  static const _denyGap = Duration(seconds: 30);

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final now = DateTime.now();
    for (final b in capture.barcodes) {
      final token = (b.rawValue ?? '').trim();
      if (token.length < 10 || token.length > 100) continue;
      final last = _seen[token];
      if (last != null && now.difference(last) < _repeatGap) continue;
      _seen[token] = now;
      if (!_queue.contains(token)) _queue.add(token);
    }
    unawaited(_drain());
  }

  Future<void> _drain() async {
    if (_working) return;
    _working = true;
    try {
      while (_queue.isNotEmpty && mounted) {
        await _handle(_queue.removeFirst());
      }
    } finally {
      _working = false;
    }
  }

  Future<void> _handle(String token) async {
    try {
      var r = await _deps.driver.scan(tripId: widget.tripId, token: token);

      if (r.result == 'needs_confirm') {
        final allow = await _askWalkIn(r);
        if (!mounted) return;
        if (!allow) {
          _seen[token] = DateTime.now().add(_denyGap - _repeatGap);
          return;
        }
        r = await _deps.driver.scan(
          tripId: widget.tripId,
          token: token,
          confirmWalkIn: true,
        );
      }

      switch (r.result) {
        case 'boarded':
          _ok();
        case 'already':
          break; // بی‌صدا
        case 'full':
          _problem(r.message ?? context.t('drv.scan_full'));
        default:
          _problem(r.message ?? context.t('drv.scan_invalid'));
      }
    } on ApiException catch (e) {
      // خطا باید اجازه‌ی تلاش دوباره بدهد.
      _seen.remove(token);
      _problem(
        e.statusCode == 404 ? context.t('drv.scan_invalid') : e.message,
      );
    }
  }

  void _ok() {
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() {
      _count++;
      _flash = true;
    });
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _flash = false);
    });
  }

  void _problem(String message) {
    HapticFeedback.heavyImpact();
    if (mounted) showMessage(context, message, tone: Tone.danger);
  }

  Future<bool> _askWalkIn(ScanResult r) {
    HapticFeedback.mediumImpact();
    return showAppDialog(
      context,
      icon: Icons.person_add_alt_1_rounded,
      title: context.t('drv.walk_in_title'),
      message: context.t('drv.walk_in_msg', {'name': r.name}),
      confirmLabel: context.t('drv.walk_in_allow'),
      cancelLabel: context.t('drv.walk_in_deny'),
      tone: Tone.warning,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('drv.scan_title')),
        actions: [
          IconButton(
            tooltip: 'flash',
            icon: Icon(_torch ? Icons.flash_on : Icons.flash_off),
            onPressed: () async {
              await _scanner.toggleTorch();
              if (mounted) setState(() => _torch = !_torch);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _scanner, onDetect: _onDetect),
          // قاب راهنما؛ با هر ثبت موفق لحظه‌ای سبز می‌شود.
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _flash ? p.success : Colors.white70,
                  width: _flash ? 6 : 3,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.t('drv.scan_count', {'n': Fa.digits(_count)}),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.t('drv.scan_hint'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
