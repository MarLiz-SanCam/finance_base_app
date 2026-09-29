import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../providers/accounts_providers.dart';
import '../../providers/database_provider.dart';

/// Formulario para mover dinero entre dos cuentas propias (retiro de cajero,
/// pago de tarjeta de crédito desde débito): no es gasto ni ingreso, así que
/// no pide categoría.
class FormTransferenciaPage extends ConsumerStatefulWidget {
  const FormTransferenciaPage({super.key});

  @override
  ConsumerState<FormTransferenciaPage> createState() =>
      _FormTransferenciaPageState();
}

class _FormTransferenciaPageState extends ConsumerState<FormTransferenciaPage> {
  final _formKey = GlobalKey<FormState>();
  final _conceptoController = TextEditingController();
  final _montoController = TextEditingController();

  DateTime _fecha = DateTime.now();
  String? _cuentaOrigenId;
  String? _cuentaDestinoId;
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
    if (_cuentaOrigenId == null || _cuentaDestinoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona la cuenta de origen y destino.'),
        ),
      );
      return;
    }
    if (_cuentaOrigenId == _cuentaDestinoId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La cuenta de origen y destino no pueden ser la misma.',
          ),
        ),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      await ref
          .read(transactionsRepositoryProvider)
          .transferir(
            concept: _conceptoController.text.trim(),
            amountCentavos: Money.pesosACentavos(_montoController.text),
            fecha: _fecha,
            cuentaOrigenId: _cuentaOrigenId!,
            cuentaDestinoId: _cuentaDestinoId!,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo registrar la transferencia: $e')),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cuentas = ref.watch(accountsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transferir entre cuentas')),
      body: SafeArea(
        child: cuentas.when(
          data: (lista) {
            if (lista.length < 2) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Necesitás al menos dos cuentas para transferir entre ellas.',
                ),
              );
            }
            _cuentaOrigenId ??= lista.first.id;
            _cuentaDestinoId ??= lista
                .firstWhere(
                  (c) => c.id != _cuentaOrigenId,
                  orElse: () => lista[1],
                )
                .id;

            return SingleChildScrollView(
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
                        hintText:
                            'Ej. Retiro cajero, pago tarjeta de crédito...',
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
                    DropdownButtonFormField<String>(
                      initialValue: _cuentaOrigenId,
                      decoration: const InputDecoration(
                        labelText: 'Cuenta origen',
                      ),
                      items: [
                        for (final cuenta in lista)
                          DropdownMenuItem(
                            value: cuenta.id,
                            child: Text(cuenta.name),
                          ),
                      ],
                      onChanged: (valor) =>
                          setState(() => _cuentaOrigenId = valor),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _cuentaDestinoId,
                      decoration: const InputDecoration(
                        labelText: 'Cuenta destino',
                      ),
                      items: [
                        for (final cuenta in lista)
                          DropdownMenuItem(
                            value: cuenta.id,
                            child: Text(cuenta.name),
                          ),
                      ],
                      onChanged: (valor) =>
                          setState(() => _cuentaDestinoId = valor),
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Guardar transferencia'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error al cargar cuentas: $e')),
        ),
      ),
    );
  }
}
