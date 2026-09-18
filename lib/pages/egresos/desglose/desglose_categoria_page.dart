import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/money.dart';
import '../../../providers/desglose_egresos_providers.dart';

/// Nivel 3 del desglose: transacciones de una categoría dentro de un grupo
/// (fijo/progresivo/variable), en la quincena actual.
class DesgloseCategoriaPage extends ConsumerWidget {
  const DesgloseCategoriaPage({
    super.key,
    required this.grupo,
    required this.categoryId,
    required this.nombreCategoria,
  });

  final GrupoGasto grupo;
  final String categoryId;
  final String nombreCategoria;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transaccionesAsync = ref.watch(
      transaccionesPorCategoriaYGrupoProvider((
        grupo: grupo,
        categoryId: categoryId,
      )),
    );
    final formatoFecha = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: Text(nombreCategoria)),
      body: transaccionesAsync.when(
        data: (transacciones) {
          if (transacciones.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Sin movimientos en esta quincena.'),
              ),
            );
          }
          final total = transacciones.fold<int>(
            0,
            (suma, t) => suma + t.amount,
          );
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${transacciones.length} movimiento(s)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      Money.centavosAPesos(total),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: transacciones.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final t = transacciones[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t.concept),
                      subtitle: Text(formatoFecha.format(t.paymentDate!)),
                      trailing: Text(
                        Money.centavosAPesos(t.amount),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Error al cargar movimientos: $error')),
      ),
    );
  }
}
