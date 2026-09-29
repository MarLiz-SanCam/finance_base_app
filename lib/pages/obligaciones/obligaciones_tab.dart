import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../core/components/amount_text.dart';
import '../../core/components/app_card.dart';
import '../../core/components/app_showcase.dart';
import '../../core/showcase/showcase_keys.dart';
import '../../core/money.dart';
import '../../data/db/app_database.dart';
import '../../data/db/enums.dart';
import '../../providers/database_provider.dart';
import '../../providers/obligations_providers.dart';
import 'form_obligacion.dart';
import 'widgets/detalle_obligacion_sheet.dart';

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

const _etiquetasEstado = {
  ObligationStatus.activo: 'Activo',
  ObligationStatus.pausado: 'Pausado',
  ObligationStatus.finalizado: 'Finalizado',
};

/// Contenido del tab "Obligaciones" de Organización: lista de obligaciones
/// (gastos fijos, progresivos e ingresos fijos), con acciones rápidas para
/// pausar/reanudar/finalizar. Tocar una la edita; crear una nueva se
/// dispara desde [OrganizacionPage].
class ObligacionesTabContent extends ConsumerWidget {
  const ObligacionesTabContent({super.key});

  void _abrirFormulario(BuildContext context, {Obligation? obligacion}) {
    mostrarFormularioObligacion(context, obligacionExistente: obligacion);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final obligacionesAsync = ref.watch(obligationsTodasStreamProvider);

    return obligacionesAsync.when(
      data: (obligaciones) {
        if (obligaciones.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No hay obligaciones registradas todavía.\n'
                'Aquí das de alta gastos fijos, créditos/préstamos e '
                'ingresos fijos para que se generen sus pagos solos.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final ordenadas = [...obligaciones]
          ..sort((a, b) {
            final ordenEstado = {
              ObligationStatus.activo: 0,
              ObligationStatus.pausado: 1,
              ObligationStatus.finalizado: 2,
            };
            final cmp = ordenEstado[a.status]!.compareTo(
              ordenEstado[b.status]!,
            );
            return cmp != 0 ? cmp : a.concept.compareTo(b.concept);
          });

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: ordenadas.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final tarjeta = _ObligacionCard(
              obligacion: ordenadas[index],
              onEditar: () =>
                  _abrirFormulario(context, obligacion: ordenadas[index]),
            );
            // Solo la primera obligación es un paso del showcase.
            if (index != 0) return tarjeta;
            return AppShowcase(
              showcaseKey: ShowcaseKeys.obligacionesPrimera,
              title: 'Tus obligaciones',
              description:
                  'Gastos fijos, créditos e ingresos fijos que se repiten; sus pagos se generan solos. Tócala para ver el detalle. Con los íconos la editas, eliminas, pausas o finalizas.',
              borderRadius: 16,
              child: tarjeta,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text('Error al cargar obligaciones: $error')),
    );
  }
}

class _ObligacionCard extends ConsumerWidget {
  const _ObligacionCard({required this.obligacion, required this.onEditar});

  final Obligation obligacion;
  final VoidCallback onEditar;

  Future<void> _cambiarEstado(WidgetRef ref, ObligationStatus status) {
    return ref
        .read(obligationsRepositoryProvider)
        .cambiarEstado(obligacion.id, status);
  }

  Future<void> _eliminar(BuildContext context, WidgetRef ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar obligación?'),
        content: Text(
          'Se eliminará "${obligacion.concept}". Las transacciones '
          'pendientes que dependían de ella se cancelarán; el historial ya '
          'pagado se conserva.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;

    try {
      await ref.read(obligationsRepositoryProvider).eliminar(obligacion.id);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final atenuado = obligacion.status != ObligationStatus.activo;
    final esProgresivo = obligacion.type == ObligationType.progresivo;

    return AppCard(
      onTap: () => mostrarDetalleObligacion(context, obligacion),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  obligacion.concept,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: atenuado ? theme.colorScheme.onSurfaceVariant : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: onEditar,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar obligación',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.only(left: 12),
              ),
              IconButton(
                onPressed: () => _eliminar(context, ref),
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Eliminar obligación',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.only(left: 12),
              ),
              if (obligacion.status != ObligationStatus.finalizado)
                PopupMenuButton<ObligationStatus>(
                  onSelected: (status) => _cambiarEstado(ref, status),
                  icon: Icon(
                    obligacion.status == ObligationStatus.activo
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                  ),
                  tooltip: obligacion.status == ObligationStatus.activo
                      ? 'Pausar'
                      : 'Reanudar',
                  padding: const EdgeInsets.only(left: 12),
                  itemBuilder: (context) => [
                    if (obligacion.status == ObligationStatus.activo)
                      const PopupMenuItem(
                        value: ObligationStatus.pausado,
                        child: Text('Pausar'),
                      ),
                    if (obligacion.status == ObligationStatus.pausado)
                      const PopupMenuItem(
                        value: ObligationStatus.activo,
                        child: Text('Reanudar'),
                      ),
                    const PopupMenuItem(
                      value: ObligationStatus.finalizado,
                      child: Text('Finalizar'),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (esProgresivo) ...[
            _FilaMonto(centavos: obligacion.totalAmount ?? 0),
            const SizedBox(height: 6),
          ],
          _FilaTipoFrecuencia(obligacion: obligacion),
          const SizedBox(height: 10),
          Row(
            children: [
              _ChipEstado(estado: obligacion.status),
              if (esProgresivo) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _ProgresoProgresivo(obligacionId: obligacion.id),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Ícono de efectivo + monto, sin etiqueta. Usada para el total del crédito
/// en las obligaciones progresivas (la fila de tipo/frecuencia de abajo ya
/// trae la cuota por periodo).
class _FilaMonto extends StatelessWidget {
  const _FilaMonto({required this.centavos});

  final int centavos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(MdiIcons.cash, color: Colors.green.shade600),
        const SizedBox(width: 8),
        AppAmountText(
          centavos,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// "Tipo – Frecuencia – [ícono] monto" (o "Monto variable" si la obligación
/// no tiene un monto fijo por periodo).
class _FilaTipoFrecuencia extends StatelessWidget {
  const _FilaTipoFrecuencia({required this.obligacion});

  final Obligation obligacion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monto = obligacion.amountPerPeriod;

    return Row(
      children: [
        Text(
          '${_etiquetasTipo[obligacion.type]} – '
          '${_etiquetasFrecuencia[obligacion.frequency]} – ',
          style: theme.textTheme.bodyMedium,
        ),
        if (monto == null)
          Expanded(
            child: Text(
              'Monto variable',
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          )
        else ...[
          Icon(MdiIcons.cash, size: 18, color: Colors.green.shade600),
          const SizedBox(width: 6),
          Flexible(
            child: AppAmountText(
              monto,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ChipEstado extends StatelessWidget {
  const _ChipEstado({required this.estado});

  final ObligationStatus estado;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (estado) {
      ObligationStatus.activo => theme.colorScheme.primary,
      ObligationStatus.pausado => theme.colorScheme.tertiary,
      ObligationStatus.finalizado => theme.colorScheme.onSurfaceVariant,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _etiquetasEstado[estado]!,
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _ProgresoProgresivo extends ConsumerWidget {
  const _ProgresoProgresivo({required this.obligacionId});

  final String obligacionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final obligacionesRepo = ref.watch(obligationsRepositoryProvider);
    return FutureBuilder<int?>(
      future: obligacionesRepo.saldoRestante(obligacionId),
      builder: (context, snapshot) {
        final restante = snapshot.data;
        if (restante == null) return const SizedBox.shrink();
        return Text(
          'Restan ${Money.centavosAPesos(restante)}',
          style: Theme.of(context).textTheme.bodySmall,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
