import 'dart:io';

import 'package:flutter/material.dart';

import 'package:hammasir_driver/core/theme/app_palette.dart';

/// آواتار: عکس کاربر یا حرف اول نام روی دایره‌ی فیروزه‌ای.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.imagePath,
    this.size = 64,
  });

  final String name;
  final String? imagePath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final path = imagePath;
    final trimmed = name.trim();
    final initial =
        trimmed.isEmpty ? '؟' : String.fromCharCode(trimmed.runes.first);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: p.brand,
        image: path == null
            ? null
            : DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover),
      ),
      alignment: Alignment.center,
      child: path == null
          ? Text(
              initial,
              style: TextStyle(
                fontSize: size * 0.42,
                fontWeight: FontWeight.w700,
                color: p.onBrand,
              ),
            )
          : null,
    );
  }
}
