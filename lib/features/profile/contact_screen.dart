import 'package:flutter/material.dart';

import 'package:hammasir_driver/core/theme/app_palette.dart';
import 'package:hammasir_driver/core/widgets/app_card.dart';
import 'package:hammasir_driver/l10n/l10n.dart';

/// ارتباط با ما.
class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(title: Text(context.t('contact.title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.apartment_rounded, color: p.brand, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.t('contact.office'),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      height: 1.9,
                      color: p.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.t('contact.note'),
            style: TextStyle(fontSize: 13, height: 1.8, color: p.textMuted),
          ),
        ],
      ),
    );
  }
}
