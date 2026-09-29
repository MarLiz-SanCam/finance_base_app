import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../core/periodo_quincenal.dart';
import '../../../providers/desglose_egresos_providers.dart';
import '../../../providers/egresos_dashboard_providers.dart';

/// Total gastado en la quincena actual, y su reparto entre gastos
/// presupuestados (ligados a una obligación fija/progresiva) y gastos no
/// planeados (sueltos, sin obligación — "gastos hormiga"). Registrar un
/// gasto nuevo se dispara desde el botón central de la barra de
/// navegación, no desde aquí.
class HeaderResumenEgresos extends ConsumerWidget {
  const HeaderResumenEgresos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAsync = ref.watch(gastoQuincenaActualProvider);
    final repartoAsync = ref.watch(presupuestadoVsNoPlaneadoProvider);
    final periodo = PeriodoQuincenal.actual();
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gastos del período ${periodo.etiqueta()}',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            totalAsync.when(
              data: (centavos) => Text(
                Money.centavosAPesos(centavos),
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (e, _) => Text(
                'No se pudo calcular',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            repartoAsync.when(
              data: (reparto) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Reparto(
                      icon: Icons.event_available_outlined,
                      label: 'Presupuestados',
                      color: theme.colorScheme.primary,
                      centavos: reparto.presupuestado,
                    ),
                  ),
                  Expanded(
                    child: _Reparto(
                      icon: Icons.bolt_outlined,
                      label: 'Gastos no planeados',
                      color: theme.colorScheme.tertiary,
                      centavos: reparto.noPlaneado,
                    ),
                  ),
                ],
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Reparto extends StatelessWidget {
  const _Reparto({
    required this.icon,
    required this.label,
    required this.color,
    required this.centavos,
  });

  final IconData icon;
  final String label;
  final Color color;
  final int centavos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          Money.centavosAPesos(centavos),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
