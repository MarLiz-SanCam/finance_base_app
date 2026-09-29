import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../providers/egresos_dashboard_providers.dart';

/// Categorías de gasto separadas en "fijas" (tienen una obligación
/// fija/progresiva activa asociada) y "variables" (no la tienen), cada una
/// como una lista horizontal desplazable.
class SeccionCategoriasGasto extends ConsumerWidget {
  const SeccionCategoriasGasto({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumen = ref.watch(categoriasGastoResumenProvider);

    return resumen.when(
      data: (categorias) {
        final fijas = categorias.where((c) => c.esFija).toList();
        final variables = categorias.where((c) => !c.esFija).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ListaCategorias(titulo: 'Gastos fijos', categorias: fijas),
            const SizedBox(height: 16),
            _ListaCategorias(titulo: 'Gastos variables', categorias: variables),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('No se pudieron cargar las categorías: $e'),
    );
  }
}

class _ListaCategorias extends StatelessWidget {
  const _ListaCategorias({required this.titulo, required this.categorias});

  final String titulo;
  final List<CategoriaGastoResumen> categorias;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        if (categorias.isEmpty)
          Text('Sin categorías registradas', style: theme.textTheme.bodySmall)
        else
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categorias.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) =>
                  _ChipCategoria(resumen: categorias[index]),
            ),
          ),
      ],
    );
  }
}

class _ChipCategoria extends StatelessWidget {
  const _ChipCategoria({required this.resumen});

  final CategoriaGastoResumen resumen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presupuesto = resumen.category.budgetLimit;
    final progreso = presupuesto > 0
        ? (resumen.gastadoEnLaQuincena / presupuesto).clamp(0.0, 1.0)
        : null;

    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            resumen.category.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            Money.centavosAPesos(resumen.gastadoEnLaQuincena),
            style: theme.textTheme.bodySmall,
          ),
          if (progreso != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: progreso, minHeight: 4),
            ),
        ],
      ),
    );
  }
}
