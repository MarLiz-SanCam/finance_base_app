import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../data/db/enums.dart';
import '../../../providers/accounts_providers.dart';
import '../../../providers/categories_providers.dart';
import '../../../providers/database_provider.dart';

/// Abre el diálogo de registro rápido de un gasto variable.
Future<void> mostrarRegistroRapidoDeGasto(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _RegistroRapidoGastoDialog(),
  );
}

/// Diálogo de registro rápido de un gasto variable: solo pide concepto y
/// monto. La cuenta y la categoría se completan solas (la primera cuenta y
/// la primera categoría de gasto disponibles) para no interrumpir el flujo
/// rápido con selects adicionales.
class _RegistroRapidoGastoDialog extends ConsumerStatefulWidget {
  const _RegistroRapidoGastoDialog();

  @override
  ConsumerState<_RegistroRapidoGastoDialog> createState() =>
      _RegistroRapidoGastoDialogState();
}

class _RegistroRapidoGastoDialogState
    extends ConsumerState<_RegistroRapidoGastoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _conceptoController = TextEditingController();
  final _montoController = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _conceptoController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      final cuentas = await ref.read(accountsStreamProvider.future);
      final categoriasGasto = await ref.read(
        categoriesByTypeStreamProvider(CategoryType.gasto).future,
      );
      if (cuentas.isEmpty || categoriasGasto.isEmpty) {
        throw StateError('Crea primero una cuenta y una categoría de gasto.');
      }

      await ref
          .read(transactionsRepositoryProvider)
          .registrar(
            concept: _conceptoController.text.trim(),
            amountCentavos: Money.pesosACentavos(_montoController.text),
            fecha: DateTime.now(),
            type: TransactionType.gasto,
            accountId: cuentas.first.id,
            categoryId: categoriasGasto.first.id,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo registrar el gasto: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar gasto rápido'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _conceptoController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Concepto',
                hintText: 'Ej. Taxi, café, propina...',
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
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
    );
  }
}
