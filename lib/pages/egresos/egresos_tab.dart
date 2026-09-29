import 'package:flutter/material.dart';

import '../../core/components/app_showcase.dart';
import '../../core/showcase/showcase_keys.dart';
import 'widgets/fila_desglose_gastos.dart';
import 'widgets/grafico_categorias_gasto.dart';
import 'widgets/header_resumen_egresos.dart';
import 'widgets/programados_por_vencer.dart';

/// Contenido del tab "Gastos" de Balance: total de la quincena con su
/// reparto presupuestado/no planeado, pagos programados por vencer con
/// acciones rápidas, desglose de gastos (carrusel) y gastos por categoría.
class EgresosTabContent extends StatelessWidget {
  const EgresosTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppShowcase(
            showcaseKey: ShowcaseKeys.gastosHeader,
            title: 'Gastos de la quincena',
            description:
                'Total gastado en la quincena en curso. Abajo se reparte entre gastos presupuestados (ligados a una obligación) y no planeados (gastos sueltos, como los "gastos hormiga").',
            borderRadius: 12,
            child: const HeaderResumenEgresos(),
          ),
          const SizedBox(height: 16),
          AppShowcase(
            showcaseKey: ShowcaseKeys.gastosProgramados,
            title: 'Programados por vencer',
            description:
                'Pagos de tus obligaciones que vencen esta quincena. Confirma con la palomita cuando pagues, o cancela el pendiente con la cruz.',
            borderRadius: 12,
            child: const ProgramadosPorVencer(),
          ),
          const SizedBox(height: 24),
          AppShowcase(
            showcaseKey: ShowcaseKeys.gastosDesglose,
            title: 'Desglose de gastos',
            description:
                'Desliza para ver el total de gastos Fijos, Progresivos y Variables. Toca la tarjeta del centro para ver su detalle por categoría.',
            borderRadius: 12,
            child: const FilaDesgloseGastos(),
          ),
          const SizedBox(height: 24),
          AppShowcase(
            showcaseKey: ShowcaseKeys.gastosCategorias,
            title: 'Gastos por categoría',
            description:
                'Cada color es una categoría y el porcentaje indica cuánto pesa en tus gastos de la quincena. Las categorías menores se agrupan en "Otras".',
            borderRadius: 12,
            child: const GraficoCategoriasGasto(),
          ),
        ],
      ),
    );
  }
}
