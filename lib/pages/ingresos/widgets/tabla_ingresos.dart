import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/money.dart';
import '../../../data/db/enums.dart';
import '../../../providers/transactions_providers.dart';

/// Tabla de movimientos de ingreso: concepto, monto y fecha, más reciente
/// primero.
class TablaIngresos extends ConsumerWidget {
  const TablaIngresos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingresosAsync = ref.watch(
      transactionsByTypeStreamProvider(TransactionType.ingreso),
    );

    return ingresosAsync.when(
      data: (ingresos) {
        if (ingresos.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Aún no hay ingresos registrados.'),
            ),
          );
        }

        final formatoFecha = DateFormat('dd/MM/yyyy');
        return Card(
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Concepto')),
                DataColumn(label: Text('Monto'), numeric: true),
                DataColumn(label: Text('Fecha')),
              ],
              rows: [
                for (final ingreso in ingresos)
                  DataRow(
                    cells: [
                      DataCell(Text(ingreso.concept)),
                      DataCell(Text(Money.centavosAPesos(ingreso.amount))),
                      DataCell(Text(formatoFecha.format(ingreso.paymentDate!))),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error al cargar los ingresos: $error'),
      ),
    );
  }
}
