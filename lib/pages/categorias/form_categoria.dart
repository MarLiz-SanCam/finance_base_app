import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../data/db/app_database.dart';
import '../../data/db/enums.dart';
import '../../providers/database_provider.dart';

const _etiquetasTipo = {
  CategoryType.ingreso: 'Ingreso',
  CategoryType.gasto: 'Gasto',
};

/// Alta o edición de una categoría. El tipo (ingreso/gasto) no se puede
/// cambiar en edición: las transacciones existentes ya asumen ese tipo.
class FormCategoriaPage extends ConsumerStatefulWidget {
  const FormCategoriaPage({super.key, this.categoriaExistente});

  final Category? categoriaExistente;

  @override
  ConsumerState<FormCategoriaPage> createState() => _FormCategoriaPageState();
}

class _FormCategoriaPageState extends ConsumerState<FormCategoriaPage> {
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
      final presupuesto = Money.pesosACentavos(
        _presupuestoController.text.isEmpty ? '0' : _presupuestoController.text,
      );
      if (_editando) {
        await repo.actualizar(
          id: widget.categoriaExistente!.id,
          name: _nombreController.text.trim(),
          presupuestoMensualCentavos: presupuesto,
        );
      } else {
        await repo.crear(
          name: _nombreController.text.trim(),
          type: _tipo,
          presupuestoMensualCentavos: presupuesto,
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar categoría' : 'Nueva categoría'),
        actions: [
          if (_editando)
            IconButton(
              onPressed: _guardando ? null : _eliminar,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar categoría',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nombreController,
                  autofocus: !_editando,
                  maxLength: 100,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Ej. Alimentación, Transporte, Salario...',
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'El nombre es obligatorio.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                if (_editando)
                  InputDecorator(
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    child: Text(_etiquetasTipo[_tipo]!),
                  )
                else
                  DropdownButtonFormField<CategoryType>(
                    initialValue: _tipo,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: [
                      for (final tipo in CategoryType.values)
                        DropdownMenuItem(
                          value: tipo,
                          child: Text(_etiquetasTipo[tipo]!),
                        ),
                    ],
                    onChanged: (valor) => setState(() => _tipo = valor!),
                  ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _presupuestoController,
                  decoration: const InputDecoration(
                    labelText: 'Presupuesto mensual (opcional)',
                    prefixText: r'$ ',
                    helperText:
                        'Solo aplica a categorías de gasto. Déjalo '
                        'en blanco si no quieres fijar un límite.',
                    helperMaxLines: 2,
                  ),
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
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
