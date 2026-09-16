import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../data/db/app_database.dart';
import '../../data/db/enums.dart';
import '../../providers/categories_providers.dart';
import 'form_categoria.dart';

/// Lista de categorías separadas en Ingresos y Gastos. Tocar una la edita;
/// el botón flotante crea una nueva (pide el tipo en el formulario).
class DashCategoriasPage extends ConsumerWidget {
  const DashCategoriasPage({super.key});

  void _abrirFormulario(BuildContext context, {Category? categoria}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FormCategoriaPage(categoriaExistente: categoria),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriasAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      body: categoriasAsync.when(
        data: (categorias) {
          if (categorias.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No hay categorías registradas todavía.'),
              ),
            );
          }
          final ingresos = categorias
              .where((c) => c.type == CategoryType.ingreso)
              .toList();
          final gastos = categorias
              .where((c) => c.type == CategoryType.gasto)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Seccion(
                titulo: 'Ingresos',
                categorias: ingresos,
                onTap: (categoria) =>
                    _abrirFormulario(context, categoria: categoria),
              ),
              const SizedBox(height: 24),
              _Seccion(
                titulo: 'Gastos',
                categorias: gastos,
                onTap: (categoria) =>
                    _abrirFormulario(context, categoria: categoria),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Error al cargar categorías: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(context),
        tooltip: 'Nueva categoría',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({
    required this.titulo,
    required this.categorias,
    required this.onTap,
  });

  final String titulo;
  final List<Category> categorias;
  final void Function(Category) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (categorias.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Sin categorías de este tipo.',
              style: theme.textTheme.bodySmall,
            ),
          )
        else
          ...categorias.map(
            (categoria) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(categoria.name),
                subtitle: categoria.budgetLimit > 0
                    ? Text(
                        'Presupuesto: ${Money.centavosAPesos(categoria.budgetLimit)}',
                      )
                    : null,
                onTap: () => onTap(categoria),
              ),
            ),
          ),
      ],
    );
  }
}
