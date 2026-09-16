import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../data/db/app_database.dart';
import '../../data/db/enums.dart';
import '../../providers/database_provider.dart';

const _etiquetasTipo = {
  AccountType.efectivo: 'Efectivo',
  AccountType.debito: 'Débito',
  AccountType.credito: 'Crédito',
};

/// Alta o edición de una cuenta. En edición no se puede tocar el saldo: se
/// deriva de las transacciones pagadas (ver `AccountsRepository`).
class FormCuentaPage extends ConsumerStatefulWidget {
  const FormCuentaPage({super.key, this.cuentaExistente});

  final Account? cuentaExistente;

  @override
  ConsumerState<FormCuentaPage> createState() => _FormCuentaPageState();
}

class _FormCuentaPageState extends ConsumerState<FormCuentaPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreController = TextEditingController(
    text: widget.cuentaExistente?.name,
  );
  final _saldoInicialController = TextEditingController(text: '0');

  late AccountType _tipo = widget.cuentaExistente?.type ?? AccountType.efectivo;
  bool _guardando = false;

  bool get _editando => widget.cuentaExistente != null;

  @override
  void dispose() {
    _nombreController.dispose();
    _saldoInicialController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      final repo = ref.read(accountsRepositoryProvider);
      if (_editando) {
        await repo.actualizar(
          id: widget.cuentaExistente!.id,
          name: _nombreController.text.trim(),
          type: _tipo,
        );
      } else {
        await repo.crear(
          name: _nombreController.text.trim(),
          type: _tipo,
          saldoInicialCentavos: Money.pesosACentavos(
            _saldoInicialController.text.isEmpty
                ? '0'
                : _saldoInicialController.text,
          ),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar la cuenta: $error')),
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
        title: const Text('¿Eliminar cuenta?'),
        content: Text(
          'Se eliminará "${widget.cuentaExistente!.name}". Esta acción no '
          'se puede deshacer.',
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
          .read(accountsRepositoryProvider)
          .eliminar(widget.cuentaExistente!.id);
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
        title: Text(_editando ? 'Editar cuenta' : 'Nueva cuenta'),
        actions: [
          if (_editando)
            IconButton(
              onPressed: _guardando ? null : _eliminar,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar cuenta',
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
                    hintText: 'Ej. Cartera, Tarjeta Banamex...',
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'El nombre es obligatorio.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<AccountType>(
                  initialValue: _tipo,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: [
                    for (final tipo in AccountType.values)
                      DropdownMenuItem(
                        value: tipo,
                        child: Text(_etiquetasTipo[tipo]!),
                      ),
                  ],
                  onChanged: (valor) => setState(() => _tipo = valor!),
                ),
                if (!_editando) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _saldoInicialController,
                    decoration: const InputDecoration(
                      labelText: 'Saldo inicial',
                      prefixText: r'$ ',
                      helperText:
                          'Después de crearla, el saldo se calcula solo '
                          'a partir de las transacciones.',
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
                ],
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
