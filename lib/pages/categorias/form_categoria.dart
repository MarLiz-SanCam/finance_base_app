import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/components/buttons.dart';
import '../../core/components/color_picker.dart';
import '../../core/components/form_field.dart';
import '../../core/money.dart';
import '../../data/db/app_database.dart';
import '../../data/db/enums.dart';
import '../../providers/database_provider.dart';

const _etiquetasTipo = {
  CategoryType.ingreso: 'Ingreso',
  CategoryType.gasto: 'Gasto',
};

/// Abre el alta o edición de una categoría en una hoja inferior.
Future<void> mostrarFormularioCategoria(
  BuildContext context, {
  Category? categoriaExistente,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => FormCategoriaSheet(categoriaExistente: categoriaExistente),
  );
}

/// Alta o edición de una categoría. El tipo (ingreso/gasto) no se puede
/// cambiar en edición: las transacciones existentes ya asumen ese tipo. El
/// presupuesto por quincena solo aplica (y solo se muestra) para categorías
/// de gasto.
class FormCategoriaSheet extends ConsumerStatefulWidget {
  const FormCategoriaSheet({super.key, this.categoriaExistente});

  final Category? categoriaExistente;

  @override
  ConsumerState<FormCategoriaSheet> createState() => _FormCategoriaSheetState();
}

class _FormCategoriaSheetState extends ConsumerState<FormCategoriaSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreController = TextEditingController(
    text: widget.categoriaExistente?.name,
  );
  late final _presupuestoController = TextEditingController(
    text: widget.categoriaExistente == null
        ? ''
        : (widget.categoriaExistente!.budgetLimit / 100).toStringAsFixed(2),
  );

  late CategoryType _tipo =
      widget.categoriaExistente?.type ?? CategoryType.gasto;
  late Color _color = widget.categoriaExistente != null
      ? Color(widget.categoriaExistente!.color)
      : appCategoryColors.first;
  bool _guardando = false;

  bool get _editando => widget.categoriaExistente != null;

  @override
  void dispose() {
    _nombreController.dispose();
    _presupuestoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      final repo = ref.read(categoriesRepositoryProvider);
      // El presupuesto solo aplica a categorías de gasto: si es de ingreso
      // el campo ni siquiera se muestra, así que se ignora lo que haya
      // quedado en el controller (ej. de un cambio de tipo antes de
      // guardar) y se guarda en 0 ("sin presupuesto asignado").
      final presupuesto = _tipo != CategoryType.gasto
          ? 0
          : Money.pesosACentavos(
              _presupuestoController.text.isEmpty
                  ? '0'
                  : _presupuestoController.text,
            );
      if (_editando) {
        await repo.actualizar(
          id: widget.categoriaExistente!.id,
          name: _nombreController.text.trim(),
          color: _color.toARGB32(),
          presupuestoQuincenalCentavos: presupuesto,
        );
      } else {
        await repo.crear(
          name: _nombreController.text.trim(),
          type: _tipo,
          color: _color.toARGB32(),
          presupuestoQuincenalCentavos: presupuesto,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar la categoría: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _eliminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar categoría?'),
        content: Text(
          'Se eliminará "${widget.categoriaExistente!.name}". Esta acción '
          'no se puede deshacer.',
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
    if (confirmar != true || !mounted) return;

    try {
      await ref
          .read(categoriesRepositoryProvider)
          .eliminar(widget.categoriaExistente!.id);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esGasto = _tipo == CategoryType.gasto;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _editando ? 'Editar Categoría' : 'Nueva Categoría',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_editando)
                        IconButton(
                          onPressed: _guardando ? null : _eliminar,
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Eliminar categoría',
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppFormTextField(
                    icon: Icons.label_outline,
                    label: 'Nombre',
                    controller: _nombreController,
                    autofocus: !_editando,
                    maxLength: 100,
                    textCapitalization: TextCapitalization.sentences,
                    hintText: 'Ej. Alimentación, Transporte, Salario...',
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return 'El nombre es obligatorio.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppFormDropdownField<CategoryType>(
                    icon: Icons.category_outlined,
                    label: 'Tipo de Categoría',
                    value: _tipo,
                    items: [
                      for (final tipo in CategoryType.values)
                        DropdownMenuItem(
                          value: tipo,
                          child: Text(_etiquetasTipo[tipo]!),
                        ),
                    ],
                    // El tipo no se puede cambiar en edición: las
                    // transacciones existentes ya asumen ese tipo.
                    onChanged: _editando
                        ? null
                        : (valor) => setState(() => _tipo = valor!),
                  ),
                  if (esGasto) ...[
                    const SizedBox(height: 12),
                    AppFormTextField(
                      icon: Symbols.universal_currency_alt,
                      label: 'Presupuesto por Quincena',
                      controller: _presupuestoController,
                      prefixText: r'$ ',
                      hintText: 'Opcional, ej. 1500.00',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      validator: (valor) {
                        if (valor == null || valor.isEmpty) return null;
                        try {
                          Money.pesosACentavos(valor);
                        } on FormatException {
                          return 'Monto inválido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Es el tope para esta quincena (1-15 y 16-fin de '
                      'mes), no para el mes completo. Déjalo en blanco si '
                      'no quieres fijar un límite.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  AppFieldLabel(icon: Icons.palette_outlined, label: 'Color'),
                  const SizedBox(height: 8),
                  AppColorPicker(
                    selected: _color,
                    onChanged: (color) => setState(() => _color = color),
                  ),
                  const SizedBox(height: 24),
                  AppPrimaryButton(
                    label: _guardando ? 'Guardando…' : 'Guardar',
                    onPressed: _guardando ? null : _guardar,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
