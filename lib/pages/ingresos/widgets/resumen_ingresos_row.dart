import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../data/db/enums.dart';
import '../../../providers/transactions_providers.dart';

/// Row superior del dashboard de ingresos: a la izquierda el total
/// ingresado en el mes en curso, a la derecha el botón para agregar un
/// nuevo ingreso.
class ResumenIngresosRow extends ConsumerWidget {
  const ResumenIngresosRow({super.key, required this.onAgregar});

  final VoidCallback onAgregar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingresosAsync = ref.watch(
      transactionsByTypeStreamProvider(TransactionType.ingreso),
    );
    final ahora = DateTime.now();
    final totalMesCentavos = ingresosAsync.maybeWhen(
      data: (ingresos) => ingresos
          .where(
            (t) =>
                t.paymentDate!.year == ahora.year &&
                t.paymentDate!.month == ahora.month,
          )
          .fold<int>(0, (suma, t) => suma + t.amount),
      orElse: () => 0,
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Ingresos de este mes',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Money.centavosAPesos(totalMesCentavos),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filled(
            onPressed: onAgregar,
            tooltip: 'Agregar ingreso',
            icon: const Icon(Icons.add),
            iconSize: 32,
            style: IconButton.styleFrom(
              minimumSize: const Size.square(64),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
