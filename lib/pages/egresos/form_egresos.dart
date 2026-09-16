import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../data/db/enums.dart';
import '../../providers/accounts_providers.dart';
import '../../providers/categories_providers.dart';
import '../../providers/database_provider.dart';

/// Formulario para registrar un gasto variable suelto: una transacción
/// directa (type=gasto, sin obligación asociada). La confirmación de pagos
/// de obligaciones fijas/progresivas pendientes se maneja en otra pantalla.
class FormEgresoPage extends ConsumerStatefulWidget {
  const FormEgresoPage({super.key});

  @override
  ConsumerState<FormEgresoPage> createState() => _FormEgresoPageState();
}

class _FormEgresoPageState extends ConsumerState<FormEgresoPage> {
  final _formKey = GlobalKey<FormState>();
  final _conceptoController = TextEditingController();
  final _montoController = TextEditingController();

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
    if (!_formKey.currentState!.validate()) return;
    if (_cuentaId == null || _categoriaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una cuenta y una categoría.'),
        ),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      await ref
          .read(transactionsRepositoryProvider)
          .registrar(
            concept: _conceptoController.text.trim(),
            amountCentavos: Money.pesosACentavos(_montoController.text),
            fecha: _fecha,
            type: TransactionType.gasto,
            accountId: _cuentaId!,
            categoryId: _categoriaId!,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo registrar el gasto: $e')),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cuentas = ref.watch(accountsStreamProvider);
    final categorias = ref.watch(
      categoriesByTypeStreamProvider(CategoryType.gasto),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar gasto')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _conceptoController,
                  maxLength: 150,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Concepto',
                    hintText: 'Ej. Supermercado, gasolina, renta...',
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'El concepto es obligatorio.';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _montoController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Monto',
                    prefixText: r'$ ',
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'El monto es obligatorio.';
                    }
                    int centavos;
                    try {
                      centavos = Money.pesosACentavos(valor);
                    } on FormatException {
                      return 'Monto inválido.';
                    }
                    if (centavos <= 0) {
                      return 'El monto debe ser mayor a cero.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fecha'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(_fecha)),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: _seleccionarFecha,
                ),
                const SizedBox(height: 8),
                cuentas.when(
                  data: (lista) {
                    if (lista.isEmpty) {
                      return const Text(
                        'No hay cuentas registradas todavía.',
                      );
                    }
                    _cuentaId ??= lista.first.id;
                    return DropdownButtonFormField<String>(
                      initialValue: _cuentaId,
                      decoration: const InputDecoration(labelText: 'Cuenta'),
                      items: [
                        for (final cuenta in lista)
                          DropdownMenuItem(
                            value: cuenta.id,
                            child: Text(cuenta.name),
                          ),
                      ],
                      onChanged: (valor) => setState(() => _cuentaId = valor),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error al cargar cuentas: $e'),
                ),
                const SizedBox(height: 16),
                categorias.when(
                  data: (lista) {
                    if (lista.isEmpty) {
                      return const Text(
                        'No hay categorías de gasto registradas todavía.',
                      );
                    }
                    _categoriaId ??= lista.first.id;
                    return DropdownButtonFormField<String>(
                      initialValue: _categoriaId,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                      ),
                      items: [
                        for (final categoria in lista)
                          DropdownMenuItem(
                            value: categoria.id,
                            child: Text(categoria.name),
                          ),
                      ],
                      onChanged: (valor) =>
                          setState(() => _categoriaId = valor),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error al cargar categorías: $e'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _guardando ? null : _guardar,
                    child: _guardando
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar gasto'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
