import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../providers/egresos_dashboard_providers.dart';

/// Card con el total de gastos ya registrados (transacciones) dentro de la
/// quincena actual.
class CardGastosRealizados extends ConsumerWidget {
  const CardGastosRealizados({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realizados = ref.watch(gastosRealizadosQuincenaProvider);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Gastos realizados',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            realizados.when(
              data: (lista) {
                if (lista.isEmpty) {
                  return Text(
                    'Sin gastos registrados aún',
                    style: theme.textTheme.bodySmall,
                  );
                }
                final totalCentavos = lista.fold<int>(
                  0,
                  (acumulado, t) => acumulado + t.amount,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Money.centavosAPesos(totalCentavos),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${lista.length} movimiento(s)',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
              error: (e, _) =>
                  Text('Error al cargar', style: theme.textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}
