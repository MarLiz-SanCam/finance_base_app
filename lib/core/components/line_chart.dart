import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Una serie del [AppLineChart]: una línea con un valor por cada etiqueta
/// del eje X.
class AppChartSeries {
  final String label;
  final Color color;
  final List<double> values;

  const AppChartSeries({
    required this.label,
    required this.color,
    required this.values,
  });
}

/// Gráfica de líneas suaves con puntos huecos, cuadrícula horizontal tenue
/// y sin bordes. Es solo el gráfico: el llamador lo envuelve en un
/// [AppCard] y agrega leyenda o selector de periodo si los necesita.
///
/// Cada serie debe traer un valor por cada entrada de [xLabels]. [formatY]
/// da el texto de cada marca del eje Y (ej. `(v) => '${v.toInt()}%'`); con
/// [minY], [maxY] e [intervalY] se fija la escala, y si se omiten se ajusta
/// sola a los datos.
class AppLineChart extends StatelessWidget {
  final List<AppChartSeries> series;
  final List<String> xLabels;
  final String Function(double value) formatY;
  final double? minY;
  final double? maxY;
  final double? intervalY;
  final double height;

  const AppLineChart({
    super.key,
    required this.series,
    required this.xLabels,
    required this.formatY,
    this.minY,
    this.maxY,
    this.intervalY,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final axisStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: 11,
      color: colorScheme.onSurface.withValues(alpha: 0.75),
    );

    return SizedBox(
      height: height,
      // Margen a la derecha: el último punto se dibuja centrado sobre el
      // borde del área y su mitad exterior se recortaría.
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (xLabels.length - 1).toDouble(),
            minY: minY,
            maxY: maxY,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: intervalY,
              getDrawingHorizontalLine: (_) => FlLine(
                color: colorScheme.onSurface.withValues(alpha: 0.08),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: intervalY,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(formatY(value), style: axisStyle),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final i = value.round();
                    if (i < 0 || i >= xLabels.length) return const SizedBox();
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(xLabels[i], style: axisStyle),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: const LineTouchData(enabled: false),
            lineBarsData: [
              for (final s in series)
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < s.values.length; i++)
                      FlSpot(i.toDouble(), s.values[i]),
                  ],
                  isCurved: true,
                  color: s.color,
                  barWidth: 2,
                  dotData: FlDotData(
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                          radius: 4,
                          color: colorScheme.surface,
                          strokeColor: s.color,
                          strokeWidth: 2,
                        ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
