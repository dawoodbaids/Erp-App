import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A single point in a line/area chart.
class ChartPoint {
  final String label;
  final double value;

  const ChartPoint({required this.label, required this.value});
}

/// Premium line/area chart used on the dashboard.
///
/// Draws a smooth grid, gradient area fill, rounded line and highlighted
/// dots. Colours are derived from the active theme so the chart works in
/// light and dark mode.
class SalesTrendChart extends StatelessWidget {
  final List<ChartPoint> points;
  final double height;

  const SalesTrendChart({super.key, required this.points, this.height = 150});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lineColor = theme.colorScheme.primary;
    final gridColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.5);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SalesTrendPainter(
          points: points,
          lineColor: lineColor,
          gridColor: gridColor,
        ),
      ),
    );
  }
}

class _SalesTrendPainter extends CustomPainter {
  final List<ChartPoint> points;
  final Color lineColor;
  final Color gridColor;

  const _SalesTrendPainter({
    required this.points,
    required this.lineColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var row = 1; row < 4; row++) {
      final y = size.height * row / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.isEmpty) return;
    final maxValue = points.fold<double>(
      0,
      (max, point) => math.max(max, point.value),
    );
    final range = maxValue == 0 ? 1.0 : maxValue;
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.22),
          lineColor.withValues(alpha: 0),
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;

    Offset pointOffset(int index) {
      final x = points.length == 1
          ? size.width / 2
          : size.width * index / (points.length - 1);
      final y =
          size.height - (points[index].value / range * (size.height - 12)) - 6;
      return Offset(x, y);
    }

    final line = Path();
    for (var index = 0; index < points.length; index++) {
      final point = pointOffset(index);
      if (index == 0) {
        line.moveTo(point.dx, point.dy);
      } else {
        line.lineTo(point.dx, point.dy);
      }
    }
    final area = Path.from(line)
      ..lineTo(pointOffset(points.length - 1).dx, size.height)
      ..lineTo(pointOffset(0).dx, size.height)
      ..close();
    canvas.drawPath(area, fillPaint);
    canvas.drawPath(line, linePaint);

    final dotPaint = Paint()..color = lineColor;
    for (var index = 0; index < points.length; index++) {
      canvas.drawCircle(pointOffset(index), 4, dotPaint);
      canvas.drawCircle(
        pointOffset(index),
        7,
        Paint()
          ..color = lineColor.withValues(alpha: 0.15)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SalesTrendPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.gridColor != gridColor;
}

/// Legend entry for the status donut chart.
class DonutEntry {
  final String label;
  final int count;
  final Color color;

  const DonutEntry({
    required this.label,
    required this.count,
    required this.color,
  });
}

/// Donut chart used to visualise invoice status distribution.
class StatusDonutChart extends StatelessWidget {
  final List<DonutEntry> entries;
  final double size;

  const StatusDonutChart({super.key, required this.entries, this.size = 132});

  @override
  Widget build(BuildContext context) {
    final trackColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final total = entries.fold<int>(0, (sum, entry) => sum + entry.count);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _StatusDonutPainter(
              entries: entries,
              trackColor: trackColor,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$total',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                'dashboard.invoices'.tr,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusDonutPainter extends CustomPainter {
  final List<DonutEntry> entries;
  final Color trackColor;

  const _StatusDonutPainter({required this.entries, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 16.0;
    final rect =
        Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, track);

    final total = entries.fold<int>(0, (sum, entry) => sum + entry.count);
    if (total == 0) return;

    var start = -math.pi / 2;
    for (final entry in entries) {
      final sweep = math.pi * 2 * entry.count / total;
      final paint = Paint()
        ..color = entry.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _StatusDonutPainter oldDelegate) =>
      oldDelegate.entries != entries || oldDelegate.trackColor != trackColor;
}
