import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../providers/egresos_dashboard_providers.dart';

/// Gráfico de línea de gastos, con selector para agrupar por día del mes en
/// curso ("mensual") o por mes del año en curso ("anual").
class GraficoGastos extends ConsumerWidget {
  const GraficoGastos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modo = ref.watch(egresosChartModeProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Gastos por período', style: theme.textTheme.titleSmall),
            SegmentedButton<EgresosChartMode>(
              segments: const [
                ButtonSegment(
                  value: EgresosChartMode.mensual,
                  label: Text('Mensual'),
                ),
                ButtonSegment(
                  value: EgresosChartMode.anual,
                  label: Text('Anual'),
                ),
              ],
              selected: {modo},
              showSelectedIcon: false,
              onSelectionChanged: (seleccion) =>
                  ref.read(egresosChartModeProvider.notifier).state =
                      seleccion.first,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: modo == EgresosChartMode.mensual
              ? const _LineaMensual()
              : const _LineaAnual(),
        ),
      ],
    );
  }
}

class _LineaMensual extends ConsumerWidget {
  const _LineaMensual();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final datos = ref.watch(gastoPorDiaDelMesProvider);
    return datos.when(
      data: (totalesPorDia) => _GraficoLinea(
        valoresCentavos: totalesPorDia,
        etiquetaEje: (indice) => '${indice + 1}',
        saltoEtiquetas: totalesPorDia.length <= 6
            ? 1
            : (totalesPorDia.length / 6).ceil(),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error al cargar el gráfico: $e')),
    );
  }
}

class _LineaAnual extends ConsumerWidget {
  const _LineaAnual();

  static const _mesesCorto = [
    'E',
    'F',
    'M',
    'A',
    'M',
    'J',
    'J',
    'A',
    'S',
    'O',
    'N',
    'D',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final datos = ref.watch(gastoPorMesDelAnioProvider);
    return datos.when(
      data: (totalesPorMes) => _GraficoLinea(
        valoresCentavos: totalesPorMes,
        etiquetaEje: (indice) => _mesesCorto[indice],
        saltoEtiquetas: 1,
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error al cargar el gráfico: $e')),
    );
  }
}

typedef _EtiquetaEje = String Function(int indice);

class _GraficoLinea extends StatelessWidget {
  const _GraficoLinea({
    required this.valoresCentavos,
    required this.etiquetaEje,
    required this.saltoEtiquetas,
  });

  final List<int> valoresCentavos;
  final _EtiquetaEje etiquetaEje;
  final int saltoEtiquetas;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.error;

    if (valoresCentavos.every((v) => v == 0)) {
      return Center(
        child: Text(
          'Sin gastos registrados en este período',
          style: theme.textTheme.bodySmall,
        ),
      );
    }

    final spots = [
      for (var i = 0; i < valoresCentavos.length; i++)
        FlSpot(
          i.toDouble(),
          Money.centavosADoublePresentacion(valoresCentavos[i]),
        ),
    ];
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY == 0 ? 1 : maxY * 1.2,
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
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
              reservedSize: 44,
              getTitlesWidget: (value, meta) => Text(
                Money.centavosAPesos((value * 100).round()),
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 9),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final indice = value.round();
                if (indice % saltoEtiquetas != 0 ||
                    indice < 0 ||
                    indice >= valoresCentavos.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    etiquetaEje(indice),
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots
                .map(
                  (s) => LineTooltipItem(
                    Money.centavosAPesos((s.y * 100).round()),
                    TextStyle(color: theme.colorScheme.onInverseSurface),
                  ),
                )
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}
