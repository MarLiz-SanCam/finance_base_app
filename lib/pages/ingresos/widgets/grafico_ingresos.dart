import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/money.dart';
import '../../../data/db/app_database.dart';
import '../../../data/db/enums.dart';
import '../../../providers/transactions_providers.dart';

enum _Periodo { quincenal, mensual, anual }

const _cantidadDePuntos = {
  _Periodo.quincenal: 8,
  _Periodo.mensual: 6,
  _Periodo.anual: 5,
};

class _PuntoHistorico {
  _PuntoHistorico(this.etiqueta, this.totalCentavos);

  final String etiqueta;
  final int totalCentavos;
}

DateTime _inicioDePeriodo(DateTime fecha, _Periodo periodo) {
  switch (periodo) {
    case _Periodo.quincenal:
      return DateTime(fecha.year, fecha.month, fecha.day <= 15 ? 1 : 16);
    case _Periodo.mensual:
      return DateTime(fecha.year, fecha.month);
    case _Periodo.anual:
      return DateTime(fecha.year);
  }
}

DateTime _periodoAnterior(DateTime inicio, _Periodo periodo) {
  switch (periodo) {
    case _Periodo.quincenal:
      if (inicio.day == 16) return DateTime(inicio.year, inicio.month, 1);
      final mesAnterior = DateTime(inicio.year, inicio.month - 1);
      return DateTime(mesAnterior.year, mesAnterior.month, 16);
    case _Periodo.mensual:
      return DateTime(inicio.year, inicio.month - 1);
    case _Periodo.anual:
      return DateTime(inicio.year - 1);
  }
}

String _etiquetaDePeriodo(DateTime inicio, _Periodo periodo) {
  switch (periodo) {
    case _Periodo.quincenal:
      final quincena = inicio.day <= 15 ? '1ra' : '2da';
      return '$quincena ${DateFormat('MMM', 'es_MX').format(inicio)}';
    case _Periodo.mensual:
      return DateFormat('MMM yy', 'es_MX').format(inicio);
    case _Periodo.anual:
      return '${inicio.year}';
  }
}

List<_PuntoHistorico> _agruparPorPeriodo(
  List<Transaction> ingresos,
  _Periodo periodo,
) {
  final cantidad = _cantidadDePuntos[periodo]!;
  var inicio = _inicioDePeriodo(DateTime.now(), periodo);
  final periodos = <DateTime>[];
  for (var i = 0; i < cantidad; i++) {
    periodos.insert(0, inicio);
    inicio = _periodoAnterior(inicio, periodo);
  }

  final totales = {for (final p in periodos) p: 0};
  for (final ingreso in ingresos) {
    final clave = _inicioDePeriodo(ingreso.paymentDate!, periodo);
    if (totales.containsKey(clave)) {
      totales[clave] = totales[clave]! + ingreso.amount;
    }
  }

  return periodos
      .map((p) => _PuntoHistorico(_etiquetaDePeriodo(p, periodo), totales[p]!))
      .toList();
}

/// Histórico de ingresos agrupado por quincena, mes o año, a elección.
class GraficoIngresos extends ConsumerStatefulWidget {
  const GraficoIngresos({super.key});

  @override
  ConsumerState<GraficoIngresos> createState() => _GraficoIngresosState();
}

class _GraficoIngresosState extends ConsumerState<GraficoIngresos> {
  _Periodo _periodo = _Periodo.quincenal;

  @override
  Widget build(BuildContext context) {
    final ingresosAsync = ref.watch(
      transactionsByTypeStreamProvider(TransactionType.ingreso),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: SegmentedButton<_Periodo>(
                segments: const [
                  ButtonSegment(
                    value: _Periodo.quincenal,
                    label: Text('Quincenal'),
                  ),
                  ButtonSegment(
                    value: _Periodo.mensual,
                    label: Text('Mensual'),
                  ),
                  ButtonSegment(value: _Periodo.anual, label: Text('Anual')),
                ],
                selected: {_periodo},
                onSelectionChanged: (seleccion) {
                  setState(() => _periodo = seleccion.first);
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: ingresosAsync.when(
                data: (ingresos) {
                  final puntos = _agruparPorPeriodo(ingresos, _periodo);
                  return _LineaHistorico(puntos: puntos);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) =>
                    Center(child: Text('Error al cargar el histórico: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineaHistorico extends StatelessWidget {
  const _LineaHistorico({required this.puntos});

  final List<_PuntoHistorico> puntos;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final formatoEje = NumberFormat.compactCurrency(
      locale: 'es_MX',
      symbol: r'$',
      decimalDigits: 0,
    );

    return LineChart(
      LineChartData(
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
              reservedSize: 56,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  formatoEje.format(value),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= puntos.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    puntos[i].etiqueta,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < puntos.length; i++)
                FlSpot(
                  i.toDouble(),
                  Money.centavosADoublePresentacion(puntos[i].totalCentavos),
                ),
            ],
            isCurved: true,
            color: color,
            barWidth: 3,
            dotData: const FlDotData(),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
