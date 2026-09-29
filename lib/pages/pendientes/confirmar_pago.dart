import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../data/db/app_database.dart';
import '../../providers/database_provider.dart';

/// Muestra el diálogo de confirmación (fecha y, si aplica, monto) y, si el
/// usuario confirma, llama a `TransactionsRepository.confirmarPago`. Usado
/// por [PendientesPage] y por "Programados por vencer" (Balance > Gastos)
/// para que ambos flujos se comporten exactamente igual.
Future<void> confirmarPagoConDialogo(
  BuildContext context,
  WidgetRef ref,
  Transaction transaccion,
) async {
  final resultado = await showDialog<_ResultadoConfirmacion>(
    context: context,
    builder: (_) => _DialogoConfirmarPago(montoActual: transaccion.amount),
  );
  if (resultado == null) return;

  try {
    await ref
        .read(transactionsRepositoryProvider)
        .confirmarPago(
          transaccion.id,
          fecha: resultado.fecha,
          montoCentavos: resultado.montoCentavos,
        );
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo confirmar: $error')));
    }
  }
}

/// Pide confirmación y, si se acepta, llama a
/// `TransactionsRepository.cancelarPago`. Usado por [PendientesPage] y por
/// "Programados por vencer" (Balance > Gastos).
Future<void> cancelarPagoConDialogo(
  BuildContext context,
  WidgetRef ref,
  Transaction transaccion,
) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('¿Cancelar este pendiente?'),
      content: Text(
        '"${transaccion.concept}" se marcará como cancelado y no '
        'afectará el saldo. Se conserva en el historial.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Volver'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Cancelar pendiente'),
        ),
      ],
    ),
  );
  if (confirmar != true) return;

  try {
    await ref.read(transactionsRepositoryProvider).cancelarPago(transaccion.id);
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo cancelar: $error')));
    }
  }
}

class _ResultadoConfirmacion {
  const _ResultadoConfirmacion({required this.fecha, this.montoCentavos});

  final DateTime fecha;
  final int? montoCentavos;
}

/// Pide fecha de pago y, si la pendiente no traía un monto fijo
/// (`montoActual == 0`), el monto real es obligatorio; si ya traía uno, el
/// campo queda prellenado y editable por si igual varió un poco.
class _DialogoConfirmarPago extends StatefulWidget {
  const _DialogoConfirmarPago({required this.montoActual});

  final int montoActual;

  @override
  State<_DialogoConfirmarPago> createState() => _DialogoConfirmarPagoState();
}

class _DialogoConfirmarPagoState extends State<_DialogoConfirmarPago> {
  final _formKey = GlobalKey<FormState>();
  final _formatoFecha = DateFormat('dd/MM/yyyy');
  late final _montoController = TextEditingController(
    text: widget.montoActual > 0
        ? (widget.montoActual / 100).toStringAsFixed(2)
        : '',
  );
  DateTime _fecha = DateTime.now();

  bool get _requiereMonto => widget.montoActual == 0;

  Future<void> _seleccionarFecha() async {
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: '¿Cuándo se pagó/cobró?',
    );
    if (seleccionada != null) setState(() => _fecha = seleccionada);
  }

  void _confirmar() {
    if (!_formKey.currentState!.validate()) return;
    final texto = _montoController.text.trim();
    final monto = texto.isEmpty ? null : Money.pesosACentavos(texto);
    Navigator.of(
      context,
    ).pop(_ResultadoConfirmacion(fecha: _fecha, montoCentavos: monto));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmar pago'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fecha'),
              subtitle: Text(_formatoFecha.format(_fecha)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _seleccionarFecha,
            ),
            TextFormField(
              controller: _montoController,
              autofocus: _requiereMonto,
              decoration: InputDecoration(
                labelText: _requiereMonto ? 'Monto (del recibo)' : 'Monto',
                prefixText: r'$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              validator: (valor) {
                final texto = (valor ?? '').trim();
                if (texto.isEmpty) {
                  return _requiereMonto
                      ? 'Indica el monto para confirmar.'
                      : null;
                }
                try {
                  if (Money.pesosACentavos(texto) <= 0) {
                    return 'El monto debe ser mayor a cero.';
                  }
                } on FormatException {
                  return 'Monto inválido.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _confirmar, child: const Text('Confirmar')),
      ],
    );
  }
}
