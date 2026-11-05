import 'package:flutter/material.dart';

import 'package:hammasir_driver/app/settings_scope.dart';
import 'package:hammasir_driver/core/theme/app_palette.dart';
import 'package:hammasir_driver/core/widgets/app_card.dart';
import 'package:hammasir_driver/core/widgets/brand_mark.dart';

/// انتخاب زبان در اولین اجرا. متن‌ها عمداً دوزبانه ثابت‌اند.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final locale = SettingsScope.of(context).locale;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              BrandMark(size: 110, lineColor: p.brand, accent: p.accent),
              const SizedBox(height: 20),
              Text(
                'زبان خود را انتخاب کنید',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: p.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose your language',
                style: TextStyle(fontSize: 15, color: p.textMuted),
              ),
              const SizedBox(height: 32),
              _LanguageCard(
                title: 'فارسی',
                subtitle: 'Persian',
                onTap: () => locale.setLanguage('fa'),
              ),
              const SizedBox(height: 12),
              _LanguageCard(
                title: 'English',
                subtitle: 'انگلیسی',
                onTap: () => locale.setLanguage('en'),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                  ),
                ),
                Text(subtitle, style: TextStyle(color: p.textMuted)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: p.brand),
        ],
      ),
    );
  }
}
