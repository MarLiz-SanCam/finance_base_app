import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../providers/desglose_egresos_providers.dart';
import '../desglose/desglose_grupo_page.dart';
import '../desglose/grupo_gasto_ui.dart';

/// Tres tarjetas (Fijos, Progresivos, Variables) con el total gastado en
/// cada grupo durante la quincena actual. Tocar una abre su desglose por
/// categoría (ver [DesgloseGrupoPage]).
class FilaDesgloseGastos extends ConsumerWidget {
  const FilaDesgloseGastos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalesAsync = ref.watch(totalesPorGrupoProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Desglose de gastos', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SizedBox(
          height: 92,
          child: totalesAsync.when(
            data: (totales) => ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: GrupoGasto.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final grupo = GrupoGasto.values[index];
                return _TarjetaGrupo(
                  grupo: grupo,
                  totalCentavos: totales[grupo] ?? 0,
                );
              },
            ),
            loading: () => const Center(child: LinearProgressIndicator()),
            error: (error, _) => Text(
              'Error al cargar el desglose: $error',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ),
      ],
    );
  }
}

class _TarjetaGrupo extends StatelessWidget {
  const _TarjetaGrupo({required this.grupo, required this.totalCentavos});

  final GrupoGasto grupo;
  final int totalCentavos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DesgloseGrupoPage(grupo: grupo)),
        ),
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                iconosGrupoGasto[grupo],
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              Text(
                etiquetasGrupoGasto[grupo]!,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                Money.centavosAPesos(totalCentavos),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
