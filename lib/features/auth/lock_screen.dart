import 'package:flutter/material.dart';

import 'package:hammasir_driver/core/theme/app_palette.dart';
import 'package:hammasir_driver/core/widgets/brand_mark.dart';
import 'package:hammasir_driver/l10n/l10n.dart';
import 'package:hammasir_driver/state/session_controller.dart';

/// قفل اثر انگشت هنگام باز شدن اپ (اگر در تنظیمات فعال شده باشد).
class LockScreen extends StatefulWidget {
  const LockScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _failed = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // بعد از اولین فریم، پنجره‌ی اثر انگشت خودکار باز می‌شود.
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });

    final ok = await widget.session.unlock();
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _busy = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.brand,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [p.brand, p.brandDeep],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Spacer(),
                BrandMark(size: 110, lineColor: Colors.white, accent: p.accent),
                const SizedBox(height: 18),
                Text(
                  context.t('app.name'),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                InkResponse(
                  onTap: _unlock,
                  radius: 56,
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.16),
                      border: Border.all(color: Colors.white54, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.fingerprint_rounded,
                      size: 54,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _failed
                      ? context.t('lock.failed')
                      : context.t('lock.touch_sensor'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, height: 1.7),
                ),
                const Spacer(),
                TextButton(
                  onPressed: widget.session.usePassword,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: Text(context.t('lock.use_password')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
