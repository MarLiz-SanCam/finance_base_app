import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../data/db/enums.dart';
import '../../../providers/categories_providers.dart';
import '../../../providers/transactions_providers.dart';

/// Presupuesto del mes en curso: suma de `budgetLimit` de las categorías de
/// gasto contra lo efectivamente gastado en el mes.
class PresupuestoPeriodo extends ConsumerWidget {
  const PresupuestoPeriodo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriasAsync = ref.watch(
      categoriesByTypeStreamProvider(CategoryType.gasto),
    );
    final egresosAsync = ref.watch(
      transactionsByTypeStreamProvider(TransactionType.gasto),
    );

    return categoriasAsync.when(
      data: (categorias) {
        final presupuestoTotal = categorias.fold<int>(
          0,
          (suma, c) => suma + c.budgetLimit,
        );

        if (presupuestoTotal == 0) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Aún no hay presupuesto asignado a categorías de gasto.',
              ),
            ),
          );
        }

        final ahora = DateTime.now();
        final gastadoMes = egresosAsync.maybeWhen(
          data: (egresos) => egresos
              .where(
                (t) =>
                    t.paymentDate!.year == ahora.year &&
                    t.paymentDate!.month == ahora.month,
              )
              .fold<int>(0, (suma, t) => suma + t.amount),
          orElse: () => 0,
        );

        final progreso = (gastadoMes / presupuestoTotal).clamp(0.0, 1.0);
        final excedido = gastadoMes > presupuestoTotal;
        final colorExceso = Theme.of(context).colorScheme.error;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Presupuesto del mes',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${Money.centavosAPesos(gastadoMes)} de '
                  '${Money.centavosAPesos(presupuestoTotal)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: excedido ? colorExceso : null,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progreso,
                    minHeight: 8,
                    color: excedido ? colorExceso : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error al cargar el presupuesto: $error'),
      ),
    );
  }
}
