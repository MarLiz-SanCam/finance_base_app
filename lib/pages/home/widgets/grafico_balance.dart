import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/components/app_showcase.dart';
import '../../../core/money.dart';
import '../../../core/showcase/showcase_keys.dart';
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
  _PuntoHistorico(this.etiqueta, this.ingresos, this.egresos);

  final String etiqueta;
  final int ingresos;
  final int egresos;
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
        (p) => _PuntoHistorico(
          _etiquetaDePeriodo(p, periodo),
          ingresos[p]!,
          egresos[p]!,
        ),
      )
      .toList();
}

/// Histórico de ingresos vs. egresos agrupado por quincena, mes o año, a
/// elección.
class GraficoBalance extends ConsumerStatefulWidget {
  const GraficoBalance({super.key});

  @override
  ConsumerState<GraficoBalance> createState() => _GraficoBalanceState();
}

class _GraficoBalanceState extends ConsumerState<GraficoBalance> {
  _Periodo _periodo = _Periodo.quincenal;

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
            Text(
              'Ingresos y gastos',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            AppShowcase(
              showcaseKey: ShowcaseKeys.resumenPeriodo,
              title: 'Periodo del histórico',
              description:
                  'Cambia entre quincena, mes o año para agrupar el histórico como prefieras.',
              borderRadius: 20,
              child: SegmentedButton<_Periodo>(
                // Sin esto, el ícono de palomita que agrega el segmento
                // seleccionado le resta ancho a su etiqueta, y "Quincena" (la
                // más larga) se parte en dos líneas justo al seleccionarla.
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                  textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12)),
                ),
                segments: const [
                  ButtonSegment(
                    value: _Periodo.quincenal,
                    label: Text('Quincena'),
                  ),
                  ButtonSegment(value: _Periodo.mensual, label: Text('Mes')),
                  ButtonSegment(value: _Periodo.anual, label: Text('Año')),
                ],
                selected: {_periodo},
                onSelectionChanged: (seleccion) {
                  setState(() => _periodo = seleccion.first);
                },
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                _Leyenda(color: colorIngresos, label: 'Ingresos'),
                _Leyenda(color: colorEgresos, label: 'Egresos'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 248,
              child: transaccionesAsync.when(
                data: (transacciones) {
                  final puntos = _agruparPorPeriodo(transacciones, _periodo);
                  return _LineasHistorico(
                    puntos: puntos,
                    colorIngresos: colorIngresos,
                    colorEgresos: colorEgresos,
                  );
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
              // Vertical en vez de horizontal: con 8 puntos (vista
              // quincenal) las etiquetas ("1ra sep", "16 oct"...) no caben
              // una junto a otra sin encimarse. En vertical cada una solo
              // necesita el ancho de un caracter, así que nunca chocan
              // entre sí sin importar cuántos puntos tenga el gráfico.
              reservedSize: 54,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= puntos.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      puntos[i].etiqueta,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
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
