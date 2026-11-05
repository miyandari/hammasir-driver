import 'package:flutter/material.dart';

import 'package:hammasir_driver/core/theme/app_palette.dart';
import 'package:hammasir_driver/core/widgets/brand_mark.dart';
import 'package:hammasir_driver/l10n/l10n.dart';
import 'package:hammasir_driver/state/session_controller.dart';

/// صفحه‌ی آغاز: نشان «ب» روی زمینه‌ی فیروزه‌ای؛ با خطای شبکه دکمه‌ی تلاش دوباره دارد.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final error = session.startupError;

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
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.8, end: 1),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) => Opacity(
                          opacity: value.clamp(0.0, 1.0),
                          child: Transform.scale(scale: value, child: child),
                        ),
                        child: BrandMark(
                          size: 150,
                          lineColor: Colors.white,
                          accent: p.accent,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        context.t('app.name'),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.t('app.tagline'),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 40),
                      if (error == null)
                        const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      else ...[
                        Text(
                          error,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: session.retry,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: p.brand,
                            minimumSize: const Size(180, 50),
                          ),
                          child: Text(context.t('common.retry')),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
