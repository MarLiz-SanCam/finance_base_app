import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../core/components/buttons.dart';
import '../../core/components/form_field.dart';
import '../../core/money.dart';
import '../../data/db/app_database.dart';
import '../../data/db/enums.dart';
import '../../providers/database_provider.dart';

const _etiquetasTipo = {
  AccountType.efectivo: 'Efectivo',
  AccountType.debito: 'Débito',
  AccountType.credito: 'Crédito',
};

/// Abre el alta o edición de una cuenta en una hoja inferior.
Future<void> mostrarFormularioCuenta(
  BuildContext context, {
  Account? cuentaExistente,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => FormCuentaSheet(cuentaExistente: cuentaExistente),
  );
}

/// Alta o edición de una cuenta. En edición no se puede tocar el saldo: se
/// deriva de las transacciones pagadas (ver `AccountsRepository`).
class FormCuentaSheet extends ConsumerStatefulWidget {
  const FormCuentaSheet({super.key, this.cuentaExistente});

  final Account? cuentaExistente;

  @override
  ConsumerState<FormCuentaSheet> createState() => _FormCuentaSheetState();
}

class _FormCuentaSheetState extends ConsumerState<FormCuentaSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreController = TextEditingController(
    text: widget.cuentaExistente?.name,
  );
  final _saldoInicialController = TextEditingController(text: '0');
  late final _limiteController = TextEditingController(
    text: widget.cuentaExistente?.creditLimit == null
        ? ''
        : (widget.cuentaExistente!.creditLimit! / 100).toStringAsFixed(2),
  );

  late final _corteController = TextEditingController(
    text: widget.cuentaExistente?.statementDay?.toString() ?? '',
  );
  late final _pagoController = TextEditingController(
    text: widget.cuentaExistente?.paymentDueDay?.toString() ?? '',
  );

  late AccountType _tipo = widget.cuentaExistente?.type ?? AccountType.efectivo;
  bool _guardando = false;

  bool get _editando => widget.cuentaExistente != null;
  bool get _esCredito => _tipo == AccountType.credito;

  @override
  void dispose() {
    _nombreController.dispose();
    _saldoInicialController.dispose();
    _limiteController.dispose();
    _corteController.dispose();
    _pagoController.dispose();
    super.dispose();
  }

  String? _validarDia(String? valor) {
    final dia = int.tryParse(valor?.trim() ?? '');
    if (dia == null || dia < 1 || dia > 31) return 'Un día entre 1 y 31.';
    return null;
  }

  String? _validarMonto(String? valor, {required bool obligatorio}) {
    if (valor == null || valor.trim().isEmpty) {
      return obligatorio ? 'Indica el límite de crédito.' : null;
    }
    try {
      final centavos = Money.pesosACentavos(valor);
      if (obligatorio && centavos <= 0) return 'Debe ser mayor a cero.';
    } on FormatException {
      return 'Monto inválido.';
    }
    return null;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      final repo = ref.read(accountsRepositoryProvider);
      final limite = _esCredito
          ? Money.pesosACentavos(_limiteController.text)
          : null;
      final diaCorte = _esCredito ? int.parse(_corteController.text) : null;
      final diaPago = _esCredito ? int.parse(_pagoController.text) : null;
      if (_editando) {
        await repo.actualizar(
          id: widget.cuentaExistente!.id,
          name: _nombreController.text.trim(),
          type: _tipo,
          limiteCreditoCentavos: limite,
          diaCorte: diaCorte,
          diaPago: diaPago,
        );
      } else {
        final saldoInicial = Money.pesosACentavos(
          _saldoInicialController.text.isEmpty
              ? '0'
              : _saldoInicialController.text,
        );
        await repo.crear(
          name: _nombreController.text.trim(),
          type: _tipo,
          // En crédito el usuario captura la deuda actual (positiva); el
          // saldo se guarda en negativo.
          saldoInicialCentavos: _esCredito ? -saldoInicial : saldoInicial,
          limiteCreditoCentavos: limite,
          diaCorte: diaCorte,
          diaPago: diaPago,
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
    final theme = Theme.of(context);
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
                          _editando ? 'Editar Cuenta' : 'Nueva Cuenta',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_editando)
                        IconButton(
                          onPressed: _guardando ? null : _eliminar,
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Eliminar cuenta',
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppFormTextField(
                    icon: Icons.badge_outlined,
                    label: 'Nombre',
                    controller: _nombreController,
                    autofocus: !_editando,
                    maxLength: 100,
                    textCapitalization: TextCapitalization.sentences,
                    hintText: 'Ej. Cartera, Tarjeta Banamex...',
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return 'El nombre es obligatorio.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppFormDropdownField<AccountType>(
                    icon: MdiIcons.walletOutline,
                    label: 'Tipo de Cuenta',
                    value: _tipo,
                    items: [
                      for (final tipo in AccountType.values)
                        DropdownMenuItem(
                          value: tipo,
                          child: Text(_etiquetasTipo[tipo]!),
                        ),
                    ],
                    onChanged: (valor) => setState(() => _tipo = valor!),
                  ),
                  if (_esCredito) ...[
                    const SizedBox(height: 12),
                    AppFormTextField(
                      icon: MdiIcons.creditCardOutline,
                      label: 'Límite de Crédito',
                      controller: _limiteController,
                      prefixText: r'$ ',
                      hintText: 'Ej. 20000.00',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      validator: (valor) =>
                          _validarMonto(valor, obligatorio: true),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppFormTextField(
                            icon: Icons.content_cut,
                            label: 'Día de Corte',
                            controller: _corteController,
                            hintText: 'Ej. 10',
                            maxLength: 2,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: _validarDia,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppFormTextField(
                            icon: Icons.event_outlined,
                            label: 'Día de Pago',
                            controller: _pagoController,
                            hintText: 'Ej. 28',
                            maxLength: 2,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: _validarDia,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (!_editando) ...[
                    const SizedBox(height: 12),
                    AppFormTextField(
                      icon: MdiIcons.cash,
                      label: _esCredito ? 'Deuda Actual' : 'Saldo Inicial',
                      controller: _saldoInicialController,
                      prefixText: r'$ ',
                      hintText: 'Ej. 500.00',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      validator: (valor) =>
                          _validarMonto(valor, obligatorio: false),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _esCredito
                          ? 'Lo que ya debes en la tarjeta. Después de '
                                'crearla, se calcula solo a partir de las '
                                'transacciones.'
                          : 'Después de crearla, el saldo se calcula solo a '
                                'partir de las transacciones.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
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
