import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../data/db/app_database.dart';
import '../../data/db/enums.dart';
import '../../providers/database_provider.dart';
import '../../providers/obligations_providers.dart';

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
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: '¿Cuándo se pagó/cobró?',
    );
    if (fecha == null || !mounted) return;

    setState(() => _procesando = true);
    try {
      await ref
          .read(transactionsRepositoryProvider)
          .confirmarPago(widget.transaccion.id, fecha: fecha);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo confirmar: $error')));
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _cancelar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Cancelar este pendiente?'),
        content: Text(
          '"${widget.transaccion.concept}" se marcará como cancelado y no '
          'afectará el saldo. Se conserva en el historial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancelar pendiente'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    setState(() => _procesando = true);
    try {
      await ref
          .read(transactionsRepositoryProvider)
          .cancelarPago(widget.transaccion.id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo cancelar: $error')));
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
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
                  Money.centavosAPesos(widget.transaccion.amount),
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
