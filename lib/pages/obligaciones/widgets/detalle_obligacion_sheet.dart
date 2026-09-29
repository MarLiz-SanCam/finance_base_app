import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/components/amount_text.dart';
import '../../../data/db/app_database.dart';
import '../../../data/db/enums.dart';
import '../../../providers/accounts_providers.dart';
import '../../../providers/categories_providers.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/transactions_providers.dart';

const _etiquetasTipo = {
  ObligationType.gastoFijo: 'Gasto Fijo',
  ObligationType.progresivo: 'Progresivo',
  ObligationType.ingresoFijo: 'Ingreso Fijo',
};

const _etiquetasFrecuencia = {
  ObligationFrequency.mensual: 'Mensual',
  ObligationFrequency.quincenal: 'Quincenal',
  ObligationFrequency.semanal: 'Semanal',
  ObligationFrequency.anual: 'Anual',
};

const _etiquetasDiaSemana = {
  DateTime.monday: 'Lunes',
  DateTime.tuesday: 'Martes',
  DateTime.wednesday: 'Miércoles',
  DateTime.thursday: 'Jueves',
  DateTime.friday: 'Viernes',
  DateTime.saturday: 'Sábado',
  DateTime.sunday: 'Domingo',
};

const _etiquetasEstadoTransaccion = {
  TransactionStatus.pendiente: 'Pendiente',
  TransactionStatus.pagado: 'Pagado',
  TransactionStatus.cancelado: 'Cancelado',
};

final _formatoFecha = DateFormat('d MMM yyyy', 'es_MX');

/// Abre el detalle de [obligacion] en una hoja inferior de solo lectura.
Future<void> mostrarDetalleObligacion(
  BuildContext context,
  Obligation obligacion,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DetalleObligacionSheet(obligacion: obligacion),
  );
}

/// Todos los detalles de una obligación, ordenados: nombre, tipo, categoría
/// y cuenta, frecuencia con sus días de pago, y por último monto(s) y las
/// fechas de pago realmente generadas por el motor (`transactions` ligadas a
/// esta obligación) — no solo las fechas configuradas en el formulario.
class DetalleObligacionSheet extends ConsumerWidget {
  const DetalleObligacionSheet({super.key, required this.obligacion});

  final Obligation obligacion;

  String _diasDePago(Obligation o) {
    switch (o.frequency) {
      case ObligationFrequency.mensual:
        return 'Día ${o.paymentDay ?? '—'} de cada mes';
      case ObligationFrequency.quincenal:
        return 'Días ${o.paymentDay ?? '—'} y ${o.paymentDay2 ?? '—'} de '
            'cada mes';
      case ObligationFrequency.semanal:
        return o.paymentDay == null
            ? '—'
            : (_etiquetasDiaSemana[o.paymentDay] ?? '—');
      case ObligationFrequency.anual:
        return o.startDate == null
            ? 'Sin fecha de referencia'
            : 'Cada año el ${DateFormat('d MMMM', 'es_MX').format(o.startDate!)}';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoriasAsync = ref.watch(categoriesStreamProvider);
    final cuentasAsync = ref.watch(accountsStreamProvider);
    final esProgresivo = obligacion.type == ObligationType.progresivo;

    final categoriaNombre = categoriasAsync.maybeWhen(
      data: (categorias) {
        for (final c in categorias) {
          if (c.id == obligacion.categoryId) return c.name;
        }
        return 'Categoría eliminada';
      },
      orElse: () => 'Cargando…',
    );

    final cuentaNombre = obligacion.accountId == null
        ? 'Sin cuenta asignada'
        : cuentasAsync.maybeWhen(
            data: (cuentas) {
              for (final c in cuentas) {
                if (c.id == obligacion.accountId) return c.name;
              }
              return 'Cuenta eliminada';
            },
            orElse: () => 'Cargando…',
          );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  obligacion.concept,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _FilaDetalle(
                  label: 'Tipo',
                  child: Text(
                    _etiquetasTipo[obligacion.type]!,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _FilaDetalle(
                        label: 'Categoría',
                        child: Text(
                          categoriaNombre,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FilaDetalle(
                        label: 'Cuenta',
                        child: Text(
                          cuentaNombre,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                    ),
                  ],
                ),
                _FilaDetalle(
                  label: 'Frecuencia',
                  child: Text(
                    '${_etiquetasFrecuencia[obligacion.frequency]} — '
                    '${_diasDePago(obligacion)}',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (esProgresivo)
                  _SeccionMontosProgresivo(obligacion: obligacion)
                else
                  _FilaDetalle(
                    label: 'Monto por periodo',
                    child: obligacion.amountPerPeriod == null
                        ? Text('Variable', style: theme.textTheme.titleSmall)
                        : AppAmountText(
                            obligacion.amountPerPeriod!,
                            style: theme.textTheme.titleSmall,
                          ),
                  ),
                const SizedBox(height: 8),
                Text('Fechas de pago', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                _ListaFechasDePago(obligacionId: obligacion.id),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilaDetalle extends StatelessWidget {
  const _FilaDetalle({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          child,
        ],
      ),
    );
  }
}

/// Monto total del crédito, cuota por periodo, saldo restante y fechas de
/// inicio/fin — exclusivo de las obligaciones `progresivo`.
class _SeccionMontosProgresivo extends ConsumerWidget {
  const _SeccionMontosProgresivo({required this.obligacion});

  final Obligation obligacion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final obligacionesRepo = ref.watch(obligationsRepositoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _FilaDetalle(
                label: 'Monto total del crédito',
                child: AppAmountText(
                  obligacion.totalAmount ?? 0,
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FilaDetalle(
                label: 'Cuota por periodo',
                child: obligacion.amountPerPeriod == null
                    ? Text('Variable', style: theme.textTheme.titleSmall)
                    : AppAmountText(
                        obligacion.amountPerPeriod!,
                        style: theme.textTheme.titleSmall,
                      ),
              ),
            ),
          ],
        ),
        FutureBuilder<int?>(
          future: obligacionesRepo.saldoRestante(obligacion.id),
          builder: (context, snapshot) {
            final restante = snapshot.data;
            if (restante == null) return const SizedBox.shrink();
            return _FilaDetalle(
              label: 'Saldo restante',
              child: AppAmountText(restante, style: theme.textTheme.titleSmall),
            );
          },
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _FilaDetalle(
                label: 'Fecha de inicio',
                child: Text(
                  obligacion.startDate == null
                      ? 'Sin definir'
                      : _formatoFecha.format(obligacion.startDate!),
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FilaDetalle(
                label: 'Fecha de fin',
                child: Text(
                  obligacion.endDate == null
                      ? 'Sin definir'
                      : _formatoFecha.format(obligacion.endDate!),
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Las transacciones (`pendiente`, `pagado` o `cancelado`) que el motor ya
/// generó para esta obligación, con su fecha real — a diferencia de
/// [DetalleObligacionSheet._diasDePago], que solo describe el patrón
/// configurado (ej. "día 15"), esto muestra las ocurrencias concretas.
class _ListaFechasDePago extends ConsumerWidget {
  const _ListaFechasDePago({required this.obligacionId});

  final String obligacionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final transaccionesAsync = ref.watch(
      transactionsByObligationStreamProvider(obligacionId),
    );

    return transaccionesAsync.when(
      data: (transacciones) {
        if (transacciones.isEmpty) {
          return Text(
            'Aún no se han generado pagos para esta obligación. Si no '
            'tiene una cuenta asignada, es justo por eso: el motor no '
            'genera pagos hasta que se le asigne una.',
            style: theme.textTheme.bodySmall,
          );
        }
        return Column(
          children: [
            for (final t in transacciones)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatoFecha.format(t.dueDate),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      _etiquetasEstadoTransaccion[t.status]!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    AppAmountText(t.amount, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Text('No se pudieron cargar los pagos: $error'),
    );
  }
}
