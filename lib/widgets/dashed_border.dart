import 'package:material_ui/material_ui.dart';

/// Garis tepi putus-putus berbentuk kotak membulat.
/// Pakai sebagai `foregroundPainter` supaya tidak tertutup isi kotak.
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;

  const DashedBorderPainter({
    required this.color,
    this.radius = 8,
    this.strokeWidth = 1.5,
    this.dash = 6,
    this.gap = 5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Digeser setengah tebal garis supaya garis tidak terpotong di tepi.
    final kotak = (Offset.zero & size).deflate(strokeWidth / 2);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(kotak, Radius.circular(radius)));

    for (final metric in path.computeMetrics()) {
      var jarak = 0.0;
      while (jarak < metric.length) {
        canvas.drawPath(metric.extractPath(jarak, jarak + dash), paint);
        jarak += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth ||
      old.dash != dash ||
      old.gap != gap;
}
