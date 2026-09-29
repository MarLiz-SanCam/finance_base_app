import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../data/db/app_database.dart';
import '../../../providers/egresos_dashboard_providers.dart';
import '../../pendientes/confirmar_pago.dart';

/// Card con los pagos programados (obligaciones fijas/progresivas
/// pendientes) que vencen dentro de la quincena vigente — a diferencia de
/// [CardProximosAVencer], que enlazaba a Pendientes sin filtrar por fecha,
/// aquí la lista completa vive en la propia pantalla con acciones rápidas
/// para confirmar o cancelar cada pago sin salir de ella.
class ProgramadosPorVencer extends ConsumerWidget {
  const ProgramadosPorVencer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendientesAsync = ref.watch(gastosProximosAVencerQuincenaProvider);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        // El contenido (ej. el texto de "sin pagos") no siempre ocupa todo
        // el ancho por sí solo; sin este SizedBox la Card se encoge a su
        // contenido y queda más angosta y a la izquierda que el resto de
        // las cards del tab, que sí ocupan el ancho completo.
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Programados por vencer', style: theme.textTheme.titleSmall),
              const SizedBox(height: 12),
              pendientesAsync.when(
                data: (lista) {
                  if (lista.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Sin pagos programados en esta quincena',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (var i = 0; i < lista.length; i++) ...[
                        if (i > 0) const Divider(height: 20),
                        _FilaProgramado(transaccion: lista[i]),
                      ],
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
                error: (e, _) => Text(
                  'Error al cargar: $e',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilaProgramado extends ConsumerStatefulWidget {
  const _FilaProgramado({required this.transaccion});

  final Transaction transaccion;

  @override
  ConsumerState<_FilaProgramado> createState() => _FilaProgramadoState();
}

class _FilaProgramadoState extends ConsumerState<_FilaProgramado> {
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

    if (_procesando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            widget.transaccion.concept,
            style: theme.textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          widget.transaccion.amount == 0
              ? 'Monto por definir'
              : Money.centavosAPesos(widget.transaccion.amount),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        IconButton(
          icon: Icon(Icons.cancel_outlined, color: theme.colorScheme.error),
          tooltip: 'Cancelar pendiente',
          onPressed: _cancelar,
        ),
        IconButton(
          icon: Icon(
            Icons.check_circle_outline,
            color: theme.colorScheme.primary,
          ),
          tooltip: 'Confirmar pago',
          onPressed: _confirmar,
        ),
      ],
    );
  }
}
