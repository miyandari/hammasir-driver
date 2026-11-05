import 'package:flutter/material.dart';

import 'package:hammasir_driver/core/theme/app_palette.dart';
import 'package:hammasir_driver/core/widgets/app_card.dart';
import 'package:hammasir_driver/core/widgets/brand_mark.dart';
import 'package:hammasir_driver/l10n/l10n.dart';

/// درباره‌ی برنامه.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(title: Text(context.t('about.title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(color: p.brand, shape: BoxShape.circle),
              child: Center(
                child: BrandMark(
                  size: 60,
                  lineColor: Colors.white,
                  accent: p.accent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              context.t('app.name'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: p.text,
              ),
            ),
          ),
          Center(
            child: Text(
              context.t('app.tagline'),
              style: TextStyle(fontSize: 13, color: p.textMuted),
            ),
          ),
          const SizedBox(height: 20),
          AppCard(
            child: Text(
              context.t('about.maintainer'),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                height: 1.9,
                color: p.text,
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Text(
              context.t('about.purpose'),
              style: TextStyle(height: 1.9, color: p.text),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              context.t('about.version', {'v': '1.0.0'}),
              style: TextStyle(fontSize: 12, color: p.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
