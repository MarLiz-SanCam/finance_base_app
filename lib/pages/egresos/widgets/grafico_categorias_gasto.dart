import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/egresos_dashboard_providers.dart';

/// Gris neutro para agrupar categorías fuera del top mostrado ("Otras"):
/// nunca se genera un color nuevo para una categoría — cada una usa el
/// suyo, elegido al crearla (ver `FormCategoriaSheet`/`AppColorPicker`).
const _colorOtras = Color(0xFF898781);

/// Cuántas categorías se muestran con su propio color antes de agrupar el
/// resto en "Otras" — tope recomendado para que una dona siga siendo
/// legible sin recurrir a la tabla/leyenda extendida.
const _topCategorias = 6;

/// Gasto por categoría en la quincena actual, como dona: cada categoría
/// mantiene el color que se le asignó al crearla; las que no entran en el
/// top se agrupan en "Otras".
class GraficoCategoriasGasto extends ConsumerWidget {
  const GraficoCategoriasGasto({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumenAsync = ref.watch(categoriasGastoResumenProvider);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gastos por categoría', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            resumenAsync.when(
              data: (categorias) {
                final conGasto =
                    categorias.where((c) => c.gastadoEnLaQuincena > 0).toList()
                      ..sort(
                        (a, b) => b.gastadoEnLaQuincena.compareTo(
                          a.gastadoEnLaQuincena,
                        ),
                      );
                if (conGasto.isEmpty) {
                  return Text(
                    'Sin gastos registrados en este período',
                    style: theme.textTheme.bodySmall,
                  );
                }

                final principales = conGasto.take(_topCategorias).toList();
                final resto = conGasto.skip(_topCategorias);
                final totalResto = resto.fold<int>(
                  0,
                  (suma, c) => suma + c.gastadoEnLaQuincena,
                );

                final segmentos = [
                  for (final c in principales)
                    (
                      nombre: c.category.name,
                      centavos: c.gastadoEnLaQuincena,
                      color: Color(c.category.color),
                    ),
                  if (totalResto > 0)
                    (nombre: 'Otras', centavos: totalResto, color: _colorOtras),
                ];
                final total = segmentos.fold<int>(
                  0,
                  (suma, s) => suma + s.centavos,
                );

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 36,
                          sections: [
                            for (final s in segmentos)
                              PieChartSectionData(
                                value: s.centavos.toDouble(),
                                color: s.color,
                                radius: 22,
                                showTitle: false,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final s in segmentos)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: _FilaLeyenda(
                                color: s.color,
                                nombre: s.nombre,
                                porcentaje: total == 0 ? 0 : s.centavos / total,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Text('Error al cargar: $e', style: theme.textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaLeyenda extends StatelessWidget {
  const _FilaLeyenda({
    required this.color,
    required this.nombre,
    required this.porcentaje,
  });

  final Color color;
  final String nombre;
  final double porcentaje;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            nombre,
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '${(porcentaje * 100).round()}%',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
