import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/components/amount_text.dart';
import '../../core/components/app_card.dart';
import '../../core/components/app_showcase.dart';
import '../../core/showcase/showcase_keys.dart';
import '../../core/components/section_title.dart';
import '../../data/db/app_database.dart';
import '../../data/db/enums.dart';
import '../../providers/categories_providers.dart';
import '../../providers/database_provider.dart';
import 'form_categoria.dart';

/// Contenido del tab "Categorías" de Organización: lista separada en
/// Ingresos y Gastos, cada una con lo movido en la quincena en curso (y, en
/// Gastos, el presupuesto quincenal de la categoría). El lápiz abre la
/// edición; el bote de basura borra directamente (con confirmación). Crear
/// una categoría nueva se dispara desde [OrganizacionPage].
class CategoriasTabContent extends ConsumerWidget {
  const CategoriasTabContent({super.key});

  void _abrirFormulario(BuildContext context, {Category? categoria}) {
    mostrarFormularioCategoria(context, categoriaExistente: categoria);
  }

  Future<void> _eliminar(
    BuildContext context,
    WidgetRef ref,
    Category categoria,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar categoría?'),
        content: Text(
          'Se eliminará "${categoria.name}". Esta acción no se puede '
          'deshacer.',
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
      await ref.read(categoriesRepositoryProvider).eliminar(categoria.id);
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
    final categoriasAsync = ref.watch(categoriasConMontoQuincenaProvider);

    return categoriasAsync.when(
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
            .where((c) => c.category.type == CategoryType.ingreso)
            .toList();
        final gastos = categorias
            .where((c) => c.category.type == CategoryType.gasto)
            .toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Seccion(
              titulo: 'Ingresos',
              categorias: ingresos,
              showcaseKey: ShowcaseKeys.categoriasIngreso,
              showcaseTitle: 'Categorías de ingresos',
              showcaseDescription:
                  'Clasifican de dónde viene tu dinero. Ves lo ingresado en la quincena en cada una. Usa el lápiz para editarla y el bote de basura para eliminarla.',
              onEditar: (categoria) =>
                  _abrirFormulario(context, categoria: categoria),
              onEliminar: (categoria) => _eliminar(context, ref, categoria),
            ),
            const SizedBox(height: 24),
            _Seccion(
              titulo: 'Gastos',
              categorias: gastos,
              showcaseKey: ShowcaseKeys.categoriasGasto,
              showcaseTitle: 'Categorías de gastos',
              showcaseDescription:
                  'Clasifican en qué gastas. Ves lo gastado en la quincena y, si le pusiste un presupuesto, el límite quincenal a su lado (gastado / presupuesto).',
              onEditar: (categoria) =>
                  _abrirFormulario(context, categoria: categoria),
              onEliminar: (categoria) => _eliminar(context, ref, categoria),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text('Error al cargar categorías: $error')),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({
    required this.titulo,
    required this.categorias,
    required this.onEditar,
    required this.onEliminar,
    required this.showcaseKey,
    required this.showcaseTitle,
    required this.showcaseDescription,
  });

  final String titulo;
  final List<CategoriaConMontoQuincena> categorias;
  final void Function(Category) onEditar;
  final void Function(Category) onEliminar;

  /// La primera categoría de la sección es un paso del showcase.
  final GlobalKey showcaseKey;
  final String showcaseTitle;
  final String showcaseDescription;

  Widget _conShowcase(int index, Widget tarjeta) {
    if (index != 0) return tarjeta;
    return AppShowcase(
      showcaseKey: showcaseKey,
      title: showcaseTitle,
      description: showcaseDescription,
      borderRadius: 16,
      child: tarjeta,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionTitle(titulo),
        const SizedBox(height: 12),
        if (categorias.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Sin categorías de este tipo.',
              style: theme.textTheme.bodySmall,
            ),
          )
        else
          for (var i = 0; i < categorias.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _conShowcase(
                i,
                _CategoriaCard(
                  resumen: categorias[i],
                  onEditar: () => onEditar(categorias[i].category),
                  onEliminar: () => onEliminar(categorias[i].category),
                ),
              ),
            ),
      ],
    );
  }
}

class _CategoriaCard extends StatelessWidget {
  const _CategoriaCard({
    required this.resumen,
    required this.onEditar,
    required this.onEliminar,
  });

  final CategoriaConMontoQuincena resumen;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoria = resumen.category;
    final esGasto = categoria.type == CategoryType.gasto;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  categoria.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: onEditar,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar categoría',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.only(left: 12),
              ),
              IconButton(
                onPressed: onEliminar,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Eliminar categoría',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.only(left: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Symbols.universal_currency_alt, color: Color(categoria.color)),
              const SizedBox(width: 8),
              AppAmountText(
                resumen.montoQuincena,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (esGasto && categoria.budgetLimit > 0) ...[
                Text(
                  '  /  ',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Icon(
                  Icons.monetization_on_outlined,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 8),
                AppAmountText(
                  categoria.budgetLimit,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
