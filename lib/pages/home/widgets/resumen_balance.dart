import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../core/periodo_quincenal.dart';
import '../../../data/db/app_database.dart';
import '../../../data/db/enums.dart';
import '../../../providers/transactions_providers.dart';

/// Balance de la quincena en curso: ingresos, egresos y la diferencia entre
/// ambos.
class ResumenBalance extends ConsumerWidget {
  const ResumenBalance({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingresosAsync = ref.watch(
      transactionsByTypeStreamProvider(TransactionType.ingreso),
    );
    final egresosAsync = ref.watch(
      transactionsByTypeStreamProvider(TransactionType.gasto),
    );
    final periodo = PeriodoQuincenal.actual();

    int totalDeLaQuincena(AsyncValue<List<Transaction>> async) =>
        async.maybeWhen(
          data: (transacciones) => transacciones
              .where(
                (t) =>
                    !t.paymentDate!.isBefore(periodo.inicio) &&
                    t.paymentDate!.isBefore(periodo.finExclusivo),
              )
              .fold<int>(0, (suma, t) => suma + t.amount),
          orElse: () => 0,
        );

    final ingresosQuincena = totalDeLaQuincena(ingresosAsync);
    final egresosQuincena = totalDeLaQuincena(egresosAsync);
    final balance = ingresosQuincena - egresosQuincena;
    final colorBalance = balance >= 0
        ? Colors.green.shade700
        : Theme.of(context).colorScheme.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balance quincena ${periodo.etiqueta()}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              Money.centavosAPesos(balance),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorBalance,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: 'Ingresos',
                    valor: Money.centavosAPesos(ingresosQuincena),
                    color: Colors.green.shade700,
                    icon: Icons.arrow_upward,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Stat(
                    label: 'Egresos',
                    valor: Money.centavosAPesos(egresosQuincena),
                    color: Theme.of(context).colorScheme.error,
                    icon: Icons.arrow_downward,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.valor,
    required this.color,
    required this.icon,
  });

  final String label;
  final String valor;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(
                valor,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
