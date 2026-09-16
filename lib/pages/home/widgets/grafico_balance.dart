import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/money.dart';
import '../../../data/db/app_database.dart';
import '../../../data/db/enums.dart';
import '../../../providers/transactions_providers.dart';

enum _Periodo { mensual, anual }

const _cantidadDePuntos = {_Periodo.mensual: 6, _Periodo.anual: 5};

class _PuntoHistorico {
  _PuntoHistorico(this.etiqueta, this.ingresos, this.egresos);

  final String etiqueta;
  final int ingresos;
  final int egresos;
}

DateTime _inicioDePeriodo(DateTime fecha, _Periodo periodo) {
  switch (periodo) {
    case _Periodo.mensual:
      return DateTime(fecha.year, fecha.month);
    case _Periodo.anual:
      return DateTime(fecha.year);
  }
}

DateTime _periodoAnterior(DateTime inicio, _Periodo periodo) {
  switch (periodo) {
    case _Periodo.mensual:
      return DateTime(inicio.year, inicio.month - 1);
    case _Periodo.anual:
      return DateTime(inicio.year - 1);
  }
}

String _etiquetaDePeriodo(DateTime inicio, _Periodo periodo) {
  switch (periodo) {
    case _Periodo.mensual:
      return DateFormat('MMM yy', 'es_MX').format(inicio);
    case _Periodo.anual:
      return '${inicio.year}';
  }
}

List<_PuntoHistorico> _agruparPorPeriodo(
  List<Transaction> transacciones,
  _Periodo periodo,
) {
  final cantidad = _cantidadDePuntos[periodo]!;
  var inicio = _inicioDePeriodo(DateTime.now(), periodo);
  final periodos = <DateTime>[];
  for (var i = 0; i < cantidad; i++) {
    periodos.insert(0, inicio);
    inicio = _periodoAnterior(inicio, periodo);
  }

  final ingresos = {for (final p in periodos) p: 0};
  final egresos = {for (final p in periodos) p: 0};
  for (final t in transacciones) {
    if (t.status != TransactionStatus.pagado) continue;
    final clave = _inicioDePeriodo(t.paymentDate!, periodo);
    if (!ingresos.containsKey(clave)) continue;
    if (t.type == TransactionType.ingreso) {
      ingresos[clave] = ingresos[clave]! + t.amount;
    } else {
      egresos[clave] = egresos[clave]! + t.amount;
    }
  }

  return periodos
      .map(
        (p) =>
            _PuntoHistorico(_etiquetaDePeriodo(p, periodo), ingresos[p]!, egresos[p]!),
      )
      .toList();
}

/// Histórico de ingresos vs. egresos agrupado por mes o año, a elección.
class GraficoBalance extends ConsumerStatefulWidget {
  const GraficoBalance({super.key});

  @override
  ConsumerState<GraficoBalance> createState() => _GraficoBalanceState();
}

class _GraficoBalanceState extends ConsumerState<GraficoBalance> {
  _Periodo _periodo = _Periodo.mensual;

  @override
  Widget build(BuildContext context) {
    final transaccionesAsync = ref.watch(transactionsStreamProvider);
    final colorIngresos = Colors.green.shade600;
    final colorEgresos = Theme.of(context).colorScheme.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                _Leyenda(color: colorIngresos, label: 'Ingresos'),
                _Leyenda(color: colorEgresos, label: 'Egresos'),
                SegmentedButton<_Periodo>(
                  segments: const [
                    ButtonSegment(value: _Periodo.mensual, label: Text('Mes')),
                    ButtonSegment(value: _Periodo.anual, label: Text('Año')),
                  ],
                  selected: {_periodo},
                  onSelectionChanged: (seleccion) {
                    setState(() => _periodo = seleccion.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: transaccionesAsync.when(
                data: (transacciones) {
                  final puntos = _agruparPorPeriodo(transacciones, _periodo);
                  return _LineasHistorico(
                    puntos: puntos,
                    colorIngresos: colorIngresos,
                    colorEgresos: colorEgresos,
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
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

class _Leyenda extends StatelessWidget {
  const _Leyenda({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _LineasHistorico extends StatelessWidget {
  const _LineasHistorico({
    required this.puntos,
    required this.colorIngresos,
    required this.colorEgresos,
  });

  final List<_PuntoHistorico> puntos;
  final Color colorIngresos;
  final Color colorEgresos;

  @override
  Widget build(BuildContext context) {
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
                  Money.centavosADoublePresentacion(puntos[i].ingresos),
                ),
            ],
            isCurved: true,
            color: colorIngresos,
            barWidth: 3,
            dotData: const FlDotData(),
            belowBarData: BarAreaData(
              show: true,
              color: colorIngresos.withValues(alpha: 0.12),
            ),
          ),
          LineChartBarData(
            spots: [
              for (var i = 0; i < puntos.length; i++)
                FlSpot(
                  i.toDouble(),
                  Money.centavosADoublePresentacion(puntos[i].egresos),
                ),
            ],
            isCurved: true,
            color: colorEgresos,
            barWidth: 3,
            dotData: const FlDotData(),
            belowBarData: BarAreaData(
              show: true,
              color: colorEgresos.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
