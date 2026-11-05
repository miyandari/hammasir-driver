import 'package:flutter/material.dart';

/// نشان «ب» هم‌مسیر: دو مبدأ که به یک مسیر می‌رسند و نقطه‌ی مقصد زرد.
/// همان طرح آیکون برنامه، به‌صورت برداری.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 120,
    this.lineColor = Colors.white,
    this.accent = const Color(0xFFF2B84B),
  });

  final double size;
  final Color lineColor;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _BrandMarkPainter(lineColor, accent),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  _BrandMarkPainter(this.lineColor, this.accent);

  final Color lineColor;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    // مختصات بر پایه‌ی بوم ۵۱۲ در ۵۱۲ آیکون؛ ناحیه‌ی طرح (x:۱۲۰..۳۹۰، y:۱۶۰..۳۶۰)
    // در یک مربع ۲۸۸ در ۲۸۸ وسط‌چین می‌شود (مرکز طرح: ۲۵۵ و ۲۶۰).
    const left = 112.0;
    const width = 288.0;
    const centerY = 260.0;
    final scale = size.width / width;

    canvas.save();
    canvas.scale(scale);
    canvas.translate(-left, width / 2 - centerY);

    final stroke = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final upper = Path()
      ..moveTo(150, 190)
      ..cubicTo(230, 190, 236, 260, 292, 260);
    final lower = Path()
      ..moveTo(150, 330)
      ..cubicTo(230, 330, 236, 260, 292, 260);
    final tail = Path()
      ..moveTo(292, 260)
      ..lineTo(318, 260);

    canvas.drawPath(upper, stroke);
    canvas.drawPath(lower, stroke);
    canvas.drawPath(tail, stroke);

    final fill = Paint()..color = lineColor;
    canvas.drawCircle(const Offset(150, 190), 30, fill);
    canvas.drawCircle(const Offset(150, 330), 30, fill);
    canvas.drawCircle(const Offset(352, 260), 38, Paint()..color = accent);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_BrandMarkPainter old) {
    return old.lineColor != lineColor || old.accent != accent;
  }
}
