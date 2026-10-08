import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/portfolio_data.dart';
import '../theme.dart';
import '../utils/format.dart';

/// Rótulo do eixo X para o ponto [i] do período.
String chartTimeLabel(PortfolioPeriod p, int i) {
  final t = pointTime(p, i);
  return switch (p) {
    PortfolioPeriod.day => formatTime(t),
    PortfolioPeriod.week || PortfolioPeriod.month => formatDayMonth(t),
    PortfolioPeriod.year => formatMonthShort(t),
  };
}

/// Rótulo completo (usado ao arrastar o dedo no gráfico).
String chartTimeLabelFull(PortfolioPeriod p, int i) {
  final t = pointTime(p, i);
  return switch (p) {
    PortfolioPeriod.day => formatTime(t),
    PortfolioPeriod.week => '${formatDayMonth(t)} ${formatTime(t)}',
    PortfolioPeriod.month => formatDayMonth(t),
    PortfolioPeriod.year => '${formatDayMonth(t)}/${t.year}',
  };
}

/// Gráfico de linha com área. Verde se terminou acima do início, vermelho se abaixo.
/// Com [onScrub], dá para arrastar o dedo e ver o valor de cada ponto.
/// Com [period], mostra o eixo X (tempo) e o eixo Y (valor).
class PerformanceChart extends StatelessWidget {
  final List<double> values;
  final double height;
  final int? highlight;
  final ValueChanged<int?>? onScrub;
  final PortfolioPeriod? period;

  const PerformanceChart({
    super.key,
    required this.values,
    this.height = 100,
    this.highlight,
    this.onScrub,
    this.period,
  });

  @override
  Widget build(BuildContext context) {
    final color = values.last >= values.first ? FinnTheme.gain : FinnTheme.red;
    final axes = period != null;
    final left = axes ? _ChartPainter.leftAxis : 0.0;

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final chart = SizedBox(
          width: w,
          height: height,
          child: CustomPaint(
            painter: _ChartPainter(values, color, highlight, period),
          ),
        );
        final scrub = onScrub;
        if (scrub == null) return chart;

        void emit(double dx) {
          final plotW = w - left;
          var i = ((dx - left) / plotW * (values.length - 1)).round();
          if (i < 0) i = 0;
          if (i > values.length - 1) i = values.length - 1;
          scrub(i);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => emit(d.localPosition.dx),
          onTapUp: (_) => scrub(null),
          onTapCancel: () => scrub(null),
          onHorizontalDragStart: (d) => emit(d.localPosition.dx),
          onHorizontalDragUpdate: (d) => emit(d.localPosition.dx),
          onHorizontalDragEnd: (_) => scrub(null),
          onHorizontalDragCancel: () => scrub(null),
          child: chart,
        );
      },
    );
  }
}

class _ChartPainter extends CustomPainter {
  static const double leftAxis = 58; // espaço dos valores (eixo Y)
  static const double bottomAxis = 20; // espaço dos horários (eixo X)

  final List<double> values;
  final Color color;
  final int? highlight;
  final PortfolioPeriod? period;
  _ChartPainter(this.values, this.color, this.highlight, this.period);

  TextPainter _text(String s, {Color c = Colors.black54, double size = 10}) {
    return TextPainter(
      text: TextSpan(text: s, style: TextStyle(color: c, fontSize: size)),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    if (n < 2) return;

    final axes = period != null;
    final left = axes ? leftAxis : 0.0;
    final bottom = axes ? bottomAxis : 0.0;
    final plotW = size.width - left;
    final plotH = size.height - bottom;

    final minV = values.reduce(math.min);
    var maxV = values.reduce(math.max);
    if (maxV - minV < 1e-9) maxV = minV + 1;

    final padTop = plotH * 0.12;
    final padBottom = plotH * 0.08;
    double yOf(double v) =>
        padTop + (1 - (v - minV) / (maxV - minV)) * (plotH - padTop - padBottom);
    Offset pt(int i) => Offset(left + i / (n - 1) * plotW, yOf(values[i]));

    // Eixos: grade horizontal + valores (Y) e horários (X).
    if (axes) {
      final grid = Paint()
        ..color = Colors.black12
        ..strokeWidth = 1;
      const yTicks = 4;
      for (var k = 0; k < yTicks; k++) {
        final v = maxV - (maxV - minV) * k / (yTicks - 1);
        final y = yOf(v);
        canvas.drawLine(Offset(left, y), Offset(size.width, y), grid);
        final tp = _text(formatAxisBRL(v));
        final ty = (y - tp.height / 2).clamp(0.0, plotH - tp.height);
        tp.paint(canvas, Offset(left - 6 - tp.width, ty));
      }

      const xTicks = 5;
      for (var k = 0; k < xTicks; k++) {
        final i = (k * (n - 1) / (xTicks - 1)).round();
        final tp = _text(chartTimeLabel(period!, i));
        final x = (left + i / (n - 1) * plotW - tp.width / 2)
            .clamp(left - 4, size.width - tp.width);
        tp.paint(canvas, Offset(x, plotH + 5));
      }
    }

    final line = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < n; i++) {
      line.lineTo(pt(i).dx, pt(i).dy);
    }

    final fill = Path.from(line)
      ..lineTo(left + plotW, plotH)
      ..lineTo(left, plotH)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.28), color.withOpacity(0)],
        ).createShader(Rect.fromLTWH(left, 0, plotW, plotH)),
    );

    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = color,
    );

    final h = highlight;
    if (h != null && h >= 0 && h < n) {
      final p = pt(h);
      canvas.drawLine(
        Offset(p.dx, 0),
        Offset(p.dx, plotH),
        Paint()
          ..color = Colors.black26
          ..strokeWidth = 1,
      );
      canvas.drawCircle(p, 6, Paint()..color = FinnTheme.white);
      canvas.drawCircle(
        p,
        6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.values != values ||
      old.color != color ||
      old.highlight != highlight ||
      old.period != period;
}
