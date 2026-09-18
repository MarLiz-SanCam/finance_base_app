import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../providers/desglose_egresos_providers.dart';
import 'desglose_categoria_page.dart';
import 'grupo_gasto_ui.dart';

/// Nivel 2 del desglose: categorías con su subtotal dentro de un grupo
/// (fijo/progresivo/variable), en la quincena actual. Tocar una categoría
/// muestra sus transacciones (nivel 3).
class DesgloseGrupoPage extends ConsumerWidget {
  const DesgloseGrupoPage({super.key, required this.grupo});

  final GrupoGasto grupo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriasAsync = ref.watch(categoriasPorGrupoProvider(grupo));

    return Scaffold(
      appBar: AppBar(title: Text(etiquetasGrupoGasto[grupo]!)),
      body: categoriasAsync.when(
        data: (categorias) {
          if (categorias.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Sin gastos de este tipo en esta quincena.'),
              ),
            );
          }
          final total = categorias.fold<int>(
            0,
            (suma, c) => suma + c.totalCentavos,
          );
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${categorias.length} categoría(s)',
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
                  itemCount: categorias.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final categoria = categorias[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(categoria.nombre),
                      trailing: Text(
                        Money.centavosAPesos(categoria.totalCentavos),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DesgloseCategoriaPage(
                            grupo: grupo,
                            categoryId: categoria.categoryId,
                            nombreCategoria: categoria.nombre,
                          ),
                        ),
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
            Center(child: Text('Error al cargar categorías: $error')),
      ),
    );
  }
}
