import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/components/buttons.dart';
import '../../../core/components/form_field.dart';
import '../../../core/money.dart';
import '../../../data/db/enums.dart';
import '../../../providers/accounts_providers.dart';
import '../../../providers/categories_providers.dart';
import '../../../providers/database_provider.dart';

const _etiquetasTipo = {
  TransactionType.gasto: 'Gasto',
  TransactionType.ingreso: 'Ingreso',
};

/// Las categorías se filtran por [CategoryType], no por [TransactionType];
/// para gasto/ingreso ambos enums comparten nombre, así que solo hace falta
/// convertir uno al otro.
CategoryType _categoryTypeDe(TransactionType tipo) => switch (tipo) {
  TransactionType.gasto => CategoryType.gasto,
  TransactionType.ingreso => CategoryType.ingreso,
  TransactionType.transferencia => throw ArgumentError(
    'El registro rápido no aplica a transferencias.',
  ),
};

/// Abre el registro rápido de un gasto o un ingreso en una hoja inferior.
/// [tipoInicial] preselecciona el tipo según desde dónde se abre (Gasto en
/// Resumen y Balance > Gastos, Ingreso en Balance > Ingresos), pero el
/// dropdown de arriba deja cambiarlo sin salir de la hoja.
Future<void> mostrarRegistroRapido(
  BuildContext context, {
  TransactionType tipoInicial = TransactionType.gasto,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => RegistroRapidoSheet(tipoInicial: tipoInicial),
  );
}

/// Hoja de registro rápido: un movimiento directo (nace pagado) de gasto o
/// ingreso, con los mismos 4 campos para ambos —concepto, monto, cuenta y
/// categoría— usando los campos prediseñados de la app para que se vea
/// igual que el resto de los formularios. No pide fecha (se usa la de
/// hoy): para eso está el formulario completo de Balance.
class RegistroRapidoSheet extends ConsumerStatefulWidget {
  const RegistroRapidoSheet({
    super.key,
    this.tipoInicial = TransactionType.gasto,
  });

  final TransactionType tipoInicial;

  @override
  ConsumerState<RegistroRapidoSheet> createState() =>
      _RegistroRapidoSheetState();
}

class _RegistroRapidoSheetState extends ConsumerState<RegistroRapidoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _conceptoController = TextEditingController();
  final _montoController = TextEditingController();

  late TransactionType _tipo = widget.tipoInicial;
  String? _cuentaId;
  String? _categoriaId;
  bool _guardando = false;

  @override
  void dispose() {
    _conceptoController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  void _cambiarTipo(TransactionType? tipo) {
    if (tipo == null || tipo == _tipo) return;
    setState(() {
      _tipo = tipo;
      // Las categorías son propias de cada tipo: la que estaba elegida deja
      // de aplicar y se vuelve a elegir sola abajo (primera del tipo nuevo).
      _categoriaId = null;
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cuentaId == null || _categoriaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una cuenta y una categoría.')),
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
            fecha: DateTime.now(),
            type: _tipo,
            accountId: _cuentaId!,
            categoryId: _categoriaId!,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo registrar: $error')));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esGasto = _tipo == TransactionType.gasto;
    final cuentasAsync = ref.watch(accountsStreamProvider);
    final categoriasAsync = ref.watch(
      categoriesByTypeStreamProvider(_categoryTypeDe(_tipo)),
    );

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
                  Text(
                    esGasto ? 'Registrar gasto' : 'Registrar ingreso',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppFormDropdownField<TransactionType>(
                    icon: Icons.swap_vert,
                    label: 'Tipo',
                    value: _tipo,
                    items: [
                      for (final tipo in TransactionType.values)
                        if (tipo != TransactionType.transferencia)
                          DropdownMenuItem(
                            value: tipo,
                            child: Text(_etiquetasTipo[tipo]!),
                          ),
                    ],
                    onChanged: _cambiarTipo,
                  ),
                  const SizedBox(height: 12),
                  AppFormTextField(
                    icon: Icons.short_text,
                    label: 'Concepto',
                    controller: _conceptoController,
                    autofocus: true,
                    maxLength: 150,
                    textCapitalization: TextCapitalization.sentences,
                    hintText: esGasto
                        ? 'Ej. Taxi, café, propina...'
                        : 'Ej. Venta, regalo, reembolso...',
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return 'El concepto es obligatorio.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppFormTextField(
                    icon: Symbols.universal_currency_alt,
                    label: 'Monto',
                    controller: _montoController,
                    prefixText: r'$ ',
                    hintText: 'Ej. 150.00',
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
                  const SizedBox(height: 12),
                  cuentasAsync.when(
                    data: (lista) {
                      if (lista.isEmpty) {
                        return Text(
                          'No hay cuentas registradas todavía.',
                          style: theme.textTheme.bodySmall,
                        );
                      }
                      _cuentaId ??= lista.first.id;
                      return AppFormDropdownField<String>(
                        icon: Symbols.account_balance_wallet,
                        label: 'Cuenta',
                        value: _cuentaId,
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
                    error: (e, _) => Text(
                      'Error al cargar cuentas: $e',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 12),
                  categoriasAsync.when(
                    data: (lista) {
                      if (lista.isEmpty) {
                        return Text(
                          esGasto
                              ? 'No hay categorías de gasto registradas todavía.'
                              : 'No hay categorías de ingreso registradas todavía.',
                          style: theme.textTheme.bodySmall,
                        );
                      }
                      _categoriaId ??= lista.first.id;
                      return AppFormDropdownField<String>(
                        icon: Icons.category_outlined,
                        label: 'Categoría',
                        value: _categoriaId,
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
                    error: (e, _) => Text(
                      'Error al cargar categorías: $e',
                      style: theme.textTheme.bodySmall,
                    ),
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
