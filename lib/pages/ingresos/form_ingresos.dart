import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../data/db/enums.dart';
import '../../providers/accounts_providers.dart';
import '../../providers/categories_providers.dart';
import '../../providers/database_provider.dart';

/// Formulario para registrar un nuevo ingreso: concepto, monto, fecha,
/// cuenta y categoría (de tipo ingreso).
class FormIngresoPage extends ConsumerStatefulWidget {
  const FormIngresoPage({super.key});

  @override
  ConsumerState<FormIngresoPage> createState() => _FormIngresoPageState();
}

class _FormIngresoPageState extends ConsumerState<FormIngresoPage> {
  final _formKey = GlobalKey<FormState>();
  final _conceptoController = TextEditingController();
  final _montoController = TextEditingController();
  final _formatoFecha = DateFormat('dd/MM/yyyy');

  DateTime _fecha = DateTime.now();
  String? _cuentaId;
  String? _categoriaId;
  bool _guardando = false;

  @override
  void dispose() {
    _conceptoController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (seleccionada != null) {
      setState(() => _fecha = seleccionada);
    }
  }

  Future<void> _guardar() async {
    final formValido = _formKey.currentState!.validate();
    if (_cuentaId == null || _categoriaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una cuenta y una categoría.')),
      );
      return;
    }
    if (!formValido) return;

    setState(() => _guardando = true);
    try {
      await ref
          .read(transactionsRepositoryProvider)
          .registrar(
            concept: _conceptoController.text.trim(),
            amountCentavos: Money.pesosACentavos(_montoController.text),
            fecha: _fecha,
            type: TransactionType.ingreso,
            accountId: _cuentaId!,
            categoryId: _categoriaId!,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar el ingreso: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cuentasAsync = ref.watch(accountsStreamProvider);
    final categoriasAsync = ref.watch(
      categoriesByTypeStreamProvider(CategoryType.ingreso),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Agregar ingreso')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _conceptoController,
                  decoration: const InputDecoration(
                    labelText: 'Concepto',
                    hintText: 'Ej. Salario, venta, freelance...',
                  ),
                  maxLength: 150,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'El concepto es obligatorio.';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _montoController,
                  decoration: const InputDecoration(
                    labelText: 'Monto',
                    prefixText: r'$ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'El monto es obligatorio.';
                    }
                    try {
                      if (Money.pesosACentavos(valor) <= 0) {
                        return 'El monto debe ser mayor a cero.';
                      }
                    } on FormatException {
                      return 'Ingresa un monto válido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _seleccionarFecha,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Fecha'),
                    child: Text(_formatoFecha.format(_fecha)),
                  ),
                ),
                const SizedBox(height: 8),
                cuentasAsync.when(
                  data: (cuentas) => DropdownButtonFormField<String>(
                    initialValue: _cuentaId,
                    decoration: const InputDecoration(labelText: 'Cuenta'),
                    items: [
                      for (final cuenta in cuentas)
                        DropdownMenuItem(
                          value: cuenta.id,
                          child: Text(cuenta.name),
                        ),
                    ],
                    onChanged: (valor) => setState(() => _cuentaId = valor),
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: LinearProgressIndicator(),
                  ),
                  error: (error, stackTrace) =>
                      Text('Error al cargar cuentas: $error'),
                ),
                const SizedBox(height: 8),
                categoriasAsync.when(
                  data: (categorias) => DropdownButtonFormField<String>(
                    initialValue: _categoriaId,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: [
                      for (final categoria in categorias)
                        DropdownMenuItem(
                          value: categoria.id,
                          child: Text(categoria.name),
                        ),
                    ],
                    onChanged: (valor) => setState(() => _categoriaId = valor),
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: LinearProgressIndicator(),
                  ),
                  error: (error, stackTrace) =>
                      Text('Error al cargar categorías: $error'),
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
                      : const Text('Guardar ingreso'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
