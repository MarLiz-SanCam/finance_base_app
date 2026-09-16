import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../providers/egresos_dashboard_providers.dart';

/// Card con los pagos de obligaciones de gasto (fijas o progresivas) que ya
/// deberían haberse pagado según su calendario y todavía no tienen una
/// transacción que los cubra.
class CardProximosAVencer extends ConsumerWidget {
  const CardProximosAVencer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendientes = ref.watch(gastosProximosAVencerProvider);
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
                  Icons.schedule_outlined,
                  size: 18,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Próximos a vencer',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            pendientes.when(
              data: (lista) {
                if (lista.isEmpty) {
                  return Text(
                    'Sin pagos pendientes',
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
                      '${lista.length} pago(s) pendiente(s)',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    ...lista.take(2).map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '• ${t.concept} · ${Money.centavosAPesos(t.amount)}',
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
