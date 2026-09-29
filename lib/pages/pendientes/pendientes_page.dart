import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../data/db/app_database.dart';
import '../../data/db/enums.dart';
import '../../providers/obligations_providers.dart';
import 'confirmar_pago.dart';

/// Cuentas por pagar/cobrar: transacciones `pendiente` generadas por el
/// motor de obligaciones, con acciones para confirmar (afecta el saldo) o
/// cancelar (se descarta sin afectar el saldo) cada una.
class PendientesPage extends ConsumerWidget {
  const PendientesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendientesAsync = ref.watch(transaccionesPendientesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pendientes')),
      body: pendientesAsync.when(
        data: (pendientes) {
          if (pendientes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No hay pagos ni cobros pendientes por ahora.'),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: pendientes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _PendienteTile(transaccion: pendientes[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Error al cargar pendientes: $error')),
      ),
    );
  }
}

class _PendienteTile extends ConsumerStatefulWidget {
  const _PendienteTile({required this.transaccion});

  final Transaction transaccion;

  @override
  ConsumerState<_PendienteTile> createState() => _PendienteTileState();
}

class _PendienteTileState extends ConsumerState<_PendienteTile> {
  bool _procesando = false;

  Future<void> _confirmar() async {
    setState(() => _procesando = true);
    await confirmarPagoConDialogo(context, ref, widget.transaccion);
    if (mounted) setState(() => _procesando = false);
  }

  Future<void> _cancelar() async {
    setState(() => _procesando = true);
    await cancelarPagoConDialogo(context, ref, widget.transaccion);
    if (mounted) setState(() => _procesando = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esIngreso = widget.transaccion.type == TransactionType.ingreso;
    final formatoFecha = DateFormat('dd/MM/yyyy');
    final vencida = widget.transaccion.dueDate.isBefore(
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  esIngreso ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 18,
                  color: esIngreso
                      ? Colors.green.shade700
                      : theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.transaccion.concept,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Text(
                  widget.transaccion.amount == 0
                      ? 'Monto por definir'
                      : Money.centavosAPesos(widget.transaccion.amount),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Vence ${formatoFecha.format(widget.transaccion.dueDate)}'
              '${vencida ? ' · atrasado' : ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: vencida ? theme.colorScheme.error : null,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _procesando ? null : _cancelar,
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _procesando ? null : _confirmar,
                  child: _procesando
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirmar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
