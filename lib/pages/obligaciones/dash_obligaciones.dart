import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../data/db/app_database.dart';
import '../../data/db/enums.dart';
import '../../providers/database_provider.dart';
import '../../providers/obligations_providers.dart';
import 'form_obligacion.dart';

const _etiquetasTipo = {
  ObligationType.gastoFijo: 'Gasto fijo',
  ObligationType.progresivo: 'Progresivo',
  ObligationType.ingresoFijo: 'Ingreso fijo',
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

/// Lista de obligaciones (gastos fijos, progresivos e ingresos fijos), con
/// acciones rápidas para pausar/reanudar/finalizar. Tocar una la edita; el
/// botón flotante crea una nueva.
class DashObligacionesPage extends ConsumerWidget {
  const DashObligacionesPage({super.key});

  void _abrirFormulario(BuildContext context, {Obligation? obligacion}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FormObligacionPage(obligacionExistente: obligacion),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final obligacionesAsync = ref.watch(obligationsTodasStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Obligaciones')),
      body: obligacionesAsync.when(
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
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _ObligacionTile(
              obligacion: ordenadas[index],
              onTap: () =>
                  _abrirFormulario(context, obligacion: ordenadas[index]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Error al cargar obligaciones: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(context),
        tooltip: 'Nueva obligación',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ObligacionTile extends ConsumerWidget {
  const _ObligacionTile({required this.obligacion, required this.onTap});

  final Obligation obligacion;
  final VoidCallback onTap;

  Future<void> _cambiarEstado(WidgetRef ref, ObligationStatus status) {
    return ref
        .read(obligationsRepositoryProvider)
        .cambiarEstado(obligacion.id, status);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final atenuado = obligacion.status != ObligationStatus.activo;

    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(
          obligacion.concept,
          style: atenuado
              ? TextStyle(color: theme.colorScheme.onSurfaceVariant)
              : null,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_etiquetasTipo[obligacion.type]} · '
              '${_etiquetasFrecuencia[obligacion.frequency]} · '
              '${obligacion.amountPerPeriod == null ? "Monto variable" : Money.centavosAPesos(obligacion.amountPerPeriod!)}',
            ),
            Row(
              children: [
                _ChipEstado(estado: obligacion.status),
                if (obligacion.type == ObligationType.progresivo) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ProgresoProgresivo(obligacionId: obligacion.id),
                  ),
                ],
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: obligacion.status == ObligationStatus.finalizado
            ? null
            : PopupMenuButton<ObligationStatus>(
                onSelected: (status) => _cambiarEstado(ref, status),
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
      ),
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
