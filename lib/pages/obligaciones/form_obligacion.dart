import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../core/components/buttons.dart';
import '../../core/components/form_field.dart';
import '../../core/money.dart';
import '../../data/db/app_database.dart';
import '../../data/db/enums.dart';
import '../../providers/accounts_providers.dart';
import '../../providers/categories_providers.dart';
import '../../providers/database_provider.dart';

const _etiquetasTipo = {
  ObligationType.gastoFijo: 'Gasto fijo',
  ObligationType.progresivo: 'Progresivo (crédito/préstamo)',
  ObligationType.ingresoFijo: 'Ingreso fijo',
};

const _etiquetasFrecuencia = {
  ObligationFrequency.mensual: 'Mensual',
  ObligationFrequency.quincenal: 'Quincenal',
  ObligationFrequency.semanal: 'Semanal',
  ObligationFrequency.anual: 'Anual',
};

const _etiquetasDiaSemana = {
  DateTime.monday: 'Lunes',
  DateTime.tuesday: 'Martes',
  DateTime.wednesday: 'Miércoles',
  DateTime.thursday: 'Jueves',
  DateTime.friday: 'Viernes',
  DateTime.saturday: 'Sábado',
  DateTime.sunday: 'Domingo',
};

/// Abre el alta o edición de una obligación en una hoja inferior.
Future<void> mostrarFormularioObligacion(
  BuildContext context, {
  Obligation? obligacionExistente,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        FormObligacionSheet(obligacionExistente: obligacionExistente),
  );
}

/// Alta o edición de una obligación (gasto fijo, progresivo o ingreso fijo).
/// `type` no se puede cambiar en edición (ver `ObligationsRepository`). Los
/// campos que no aplican al tipo o a la frecuencia elegidos se ocultan en
/// vez de mostrarse deshabilitados: el total/fecha de fin de la deuda son
/// exclusivos de `progresivo`; los días de pago dependen de la frecuencia;
/// la fecha de inicio solo es relevante para `progresivo` y `anual` (ver
/// `ObligationSchedule`, que es el único lugar donde `mensual`/`quincenal`/
/// `semanal` la usarían, y no lo hacen).
class FormObligacionSheet extends ConsumerStatefulWidget {
  const FormObligacionSheet({super.key, this.obligacionExistente});

  final Obligation? obligacionExistente;

  @override
  ConsumerState<FormObligacionSheet> createState() =>
      _FormObligacionSheetState();
}

class _FormObligacionSheetState extends ConsumerState<FormObligacionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _formatoFecha = DateFormat('dd/MM/yyyy');

  late final _conceptoController = TextEditingController(
    text: widget.obligacionExistente?.concept,
  );
  late final _montoController = TextEditingController(
    text: widget.obligacionExistente?.amountPerPeriod == null
        ? ''
        : (widget.obligacionExistente!.amountPerPeriod! / 100).toStringAsFixed(
            2,
          ),
  );
  late final _totalController = TextEditingController(
    text: widget.obligacionExistente?.totalAmount == null
        ? ''
        : (widget.obligacionExistente!.totalAmount! / 100).toStringAsFixed(2),
  );
  late final _diaMesController = TextEditingController(
    text: widget.obligacionExistente?.frequency == ObligationFrequency.mensual
        ? widget.obligacionExistente?.paymentDay?.toString()
        : null,
  );
  late final _diaQuincena1Controller = TextEditingController(
    text: widget.obligacionExistente?.frequency == ObligationFrequency.quincenal
        ? widget.obligacionExistente?.paymentDay?.toString()
        : null,
  );
  late final _diaQuincena2Controller = TextEditingController(
    text: widget.obligacionExistente?.frequency == ObligationFrequency.quincenal
        ? widget.obligacionExistente?.paymentDay2?.toString()
        : null,
  );
  late final _fechaInicioController = TextEditingController(
    text: widget.obligacionExistente?.startDate == null
        ? ''
        : _formatoFecha.format(widget.obligacionExistente!.startDate!),
  );
  late final _fechaFinController = TextEditingController(
    text: widget.obligacionExistente?.endDate == null
        ? ''
        : _formatoFecha.format(widget.obligacionExistente!.endDate!),
  );

  late ObligationType _tipo =
      widget.obligacionExistente?.type ?? ObligationType.gastoFijo;
  late ObligationFrequency _frecuencia =
      widget.obligacionExistente?.frequency ?? ObligationFrequency.mensual;
  late String? _categoriaId = widget.obligacionExistente?.categoryId;
  late String? _cuentaId = widget.obligacionExistente?.accountId;
  late int _diaSemana =
      widget.obligacionExistente?.frequency == ObligationFrequency.semanal
      ? (widget.obligacionExistente?.paymentDay ?? DateTime.monday)
      : DateTime.monday;
  late DateTime? _fechaInicio = widget.obligacionExistente?.startDate;
  late DateTime? _fechaFin = widget.obligacionExistente?.endDate;
  bool _guardando = false;

  bool get _editando => widget.obligacionExistente != null;
  bool get _esProgresivo => _tipo == ObligationType.progresivo;
  bool get _fechaInicioRequerida =>
      _esProgresivo || _frecuencia == ObligationFrequency.anual;
  CategoryType get _tipoCategoriaEsperado => _tipo == ObligationType.ingresoFijo
      ? CategoryType.ingreso
      : CategoryType.gasto;

  @override
  void dispose() {
    _conceptoController.dispose();
    _montoController.dispose();
    _totalController.dispose();
    _diaMesController.dispose();
    _diaQuincena1Controller.dispose();
    _diaQuincena2Controller.dispose();
    _fechaInicioController.dispose();
    _fechaFinController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFechaInicio() async {
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (seleccionada == null) return;
    setState(() {
      _fechaInicio = seleccionada;
      _fechaInicioController.text = _formatoFecha.format(seleccionada);
    });
  }

  Future<void> _seleccionarFechaFin() async {
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (seleccionada == null) return;
    setState(() {
      _fechaFin = seleccionada;
      _fechaFinController.text = _formatoFecha.format(seleccionada);
    });
  }

  ({int? dia1, int? dia2}) _diasDePagoSeleccionados() {
    switch (_frecuencia) {
      case ObligationFrequency.mensual:
        return (dia1: int.tryParse(_diaMesController.text), dia2: null);
      case ObligationFrequency.semanal:
        return (dia1: _diaSemana, dia2: null);
      case ObligationFrequency.quincenal:
        return (
          dia1: int.tryParse(_diaQuincena1Controller.text),
          dia2: int.tryParse(_diaQuincena2Controller.text),
        );
      case ObligationFrequency.anual:
        return (dia1: null, dia2: null);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una categoría.')),
      );
      return;
    }
    if (_fechaInicioRequerida && _fechaInicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una fecha de inicio.')),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      final repo = ref.read(obligationsRepositoryProvider);
      final montoTexto = _montoController.text.trim();
      final montoCentavos = montoTexto.isEmpty
          ? null
          : Money.pesosACentavos(montoTexto);
      final totalCentavos = _esProgresivo
          ? Money.pesosACentavos(_totalController.text)
          : null;
      final diasDePago = _diasDePagoSeleccionados();

      if (_editando) {
        await repo.actualizar(
          id: widget.obligacionExistente!.id,
          concept: _conceptoController.text.trim(),
          categoryId: _categoriaId!,
          accountId: _cuentaId,
          frequency: _frecuencia,
          amountPerPeriodCentavos: montoCentavos,
          paymentDay: diasDePago.dia1,
          paymentDay2: diasDePago.dia2,
          totalAmountCentavos: totalCentavos,
          startDate: _fechaInicio,
          endDate: _fechaFin,
        );
      } else {
        await repo.crear(
          concept: _conceptoController.text.trim(),
          categoryId: _categoriaId!,
          accountId: _cuentaId,
          type: _tipo,
          frequency: _frecuencia,
          amountPerPeriodCentavos: montoCentavos,
          paymentDay: diasDePago.dia1,
          paymentDay2: diasDePago.dia2,
          totalAmountCentavos: totalCentavos,
          startDate: _fechaInicio,
          endDate: _fechaFin,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar la obligación: $error')),
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
        title: const Text('¿Eliminar obligación?'),
        content: Text(
          'Se eliminará "${widget.obligacionExistente!.concept}". Las '
          'transacciones pendientes que dependían de ella se cancelarán; '
          'el historial ya pagado se conserva.',
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

    await ref
        .read(obligationsRepositoryProvider)
        .eliminar(widget.obligacionExistente!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriasAsync = ref.watch(
      categoriesByTypeStreamProvider(_tipoCategoriaEsperado),
    );
    final cuentasAsync = ref.watch(accountsStreamProvider);

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
                          _editando ? 'Editar Obligación' : 'Nueva Obligación',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_editando)
                        IconButton(
                          onPressed: _guardando ? null : _eliminar,
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Eliminar obligación',
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppFormTextField(
                    icon: Icons.description_outlined,
                    label: 'Concepto',
                    controller: _conceptoController,
                    autofocus: !_editando,
                    maxLength: 150,
                    textCapitalization: TextCapitalization.sentences,
                    hintText: 'Ej. Renta, Netflix, Préstamo laptop...',
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return 'El concepto es obligatorio.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppFormDropdownField<ObligationType>(
                    icon: Icons.category_outlined,
                    label: 'Tipo',
                    value: _tipo,
                    items: [
                      for (final tipo in ObligationType.values)
                        DropdownMenuItem(
                          value: tipo,
                          child: Text(_etiquetasTipo[tipo]!),
                        ),
                    ],
                    // El tipo no se puede cambiar en edición: determina el
                    // tipo de categoría esperado y si aplican los campos de
                    // progresivo.
                    onChanged: _editando
                        ? null
                        : (valor) => setState(() {
                            _tipo = valor!;
                            _categoriaId = null;
                          }),
                  ),
                  const SizedBox(height: 12),
                  _CampoCategoria(
                    icon: Icons.label_outline,
                    categoriasAsync: categoriasAsync,
                    categoriaId: _categoriaId,
                    tipoEsperado: _tipoCategoriaEsperado,
                    onChanged: (valor) => setState(() => _categoriaId = valor),
                    onCategoriaHuerfana: () =>
                        setState(() => _categoriaId = null),
                  ),
                  const SizedBox(height: 12),
                  _CampoCuenta(
                    icon: MdiIcons.walletOutline,
                    cuentasAsync: cuentasAsync,
                    cuentaId: _cuentaId,
                    onChanged: (valor) => setState(() => _cuentaId = valor),
                  ),
                  const SizedBox(height: 12),
                  AppFormDropdownField<ObligationFrequency>(
                    icon: Icons.repeat,
                    label: 'Frecuencia',
                    value: _frecuencia,
                    items: [
                      for (final frecuencia in ObligationFrequency.values)
                        DropdownMenuItem(
                          value: frecuencia,
                          child: Text(_etiquetasFrecuencia[frecuencia]!),
                        ),
                    ],
                    onChanged: (valor) => setState(() => _frecuencia = valor!),
                  ),
                  const SizedBox(height: 12),
                  _CampoDiaDePago(
                    frecuencia: _frecuencia,
                    diaMesController: _diaMesController,
                    diaQuincena1Controller: _diaQuincena1Controller,
                    diaQuincena2Controller: _diaQuincena2Controller,
                    diaSemana: _diaSemana,
                    onDiaSemanaChanged: (valor) =>
                        setState(() => _diaSemana = valor),
                  ),
                  const SizedBox(height: 12),
                  AppFormTextField(
                    icon: MdiIcons.cash,
                    label: _esProgresivo
                        ? 'Cuota por Periodo'
                        : 'Monto por Periodo',
                    controller: _montoController,
                    prefixText: r'$ ',
                    hintText: 'Opcional, ej. 500.00',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    validator: (valor) {
                      final texto = (valor ?? '').trim();
                      if (texto.isEmpty) return null;
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
                  const SizedBox(height: 6),
                  Text(
                    'Déjalo vacío si varía cada vez (ej. luz, agua). Se '
                    'pedirá el monto real al confirmar cada pago.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_esProgresivo) ...[
                    const SizedBox(height: 12),
                    AppFormTextField(
                      icon: MdiIcons.cashMultiple,
                      label: 'Monto Total de la Deuda',
                      controller: _totalController,
                      prefixText: r'$ ',
                      hintText: 'Ej. 15000.00',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      validator: (valor) {
                        if (valor == null || valor.trim().isEmpty) {
                          return 'El monto total es obligatorio.';
                        }
                        try {
                          if (Money.pesosACentavos(valor) <= 0) {
                            return 'El monto total debe ser mayor a cero.';
                          }
                        } on FormatException {
                          return 'Monto inválido.';
                        }
                        return null;
                      },
                    ),
                  ],
                  if (_fechaInicioRequerida) ...[
                    const SizedBox(height: 12),
                    AppFormTextField(
                      icon: Icons.calendar_today_outlined,
                      label: 'Fecha de Inicio',
                      controller: _fechaInicioController,
                      readOnly: true,
                      hintText: 'Selecciona una fecha',
                      onTap: _seleccionarFechaInicio,
                    ),
                  ],
                  if (_esProgresivo) ...[
                    const SizedBox(height: 12),
                    AppFormTextField(
                      icon: Icons.event_busy_outlined,
                      label: 'Fecha de Fin (opcional)',
                      controller: _fechaFinController,
                      readOnly: true,
                      hintText: 'Selecciona una fecha',
                      onTap: _seleccionarFechaFin,
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

/// Selector de categoría, filtrado al tipo esperado según el tipo de
/// obligación. Si la categoría antes elegida ya no existe en la lista
/// (ej. se borró), avisa vía [onCategoriaHuerfana] para que el padre limpie
/// la selección.
class _CampoCategoria extends StatelessWidget {
  const _CampoCategoria({
    required this.icon,
    required this.categoriasAsync,
    required this.categoriaId,
    required this.tipoEsperado,
    required this.onChanged,
    required this.onCategoriaHuerfana,
  });

  final IconData icon;
  final AsyncValue<List<Category>> categoriasAsync;
  final String? categoriaId;
  final CategoryType tipoEsperado;
  final ValueChanged<String?> onChanged;
  final VoidCallback onCategoriaHuerfana;

  @override
  Widget build(BuildContext context) {
    return categoriasAsync.when(
      data: (categorias) {
        if (categorias.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppFieldLabel(icon: icon, label: 'Categoría'),
              const SizedBox(height: 6),
              Text(
                'No hay categorías de tipo '
                '${tipoEsperado == CategoryType.ingreso ? "ingreso" : "gasto"} '
                'todavía. Crea una primero.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        }
        final esHuerfana =
            categoriaId != null && categorias.every((c) => c.id != categoriaId);
        if (esHuerfana) {
          // No se puede limpiar el estado del padre en mitad de un build
          // (setState durante build), así que se avisa para el próximo
          // frame; mientras tanto, el dropdown de este mismo build recibe
          // `null` para no pasarle un value que no está en `items` (el
          // dropdown exige que coincida con alguno o sea null).
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => onCategoriaHuerfana(),
          );
        }
        return AppFormDropdownField<String>(
          icon: icon,
          label: 'Categoría',
          value: esHuerfana ? null : categoriaId,
          items: [
            for (final categoria in categorias)
              DropdownMenuItem(
                value: categoria.id,
                child: Text(categoria.name),
              ),
          ],
          onChanged: onChanged,
        );
      },
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppFieldLabel(icon: icon, label: 'Categoría'),
          const SizedBox(height: 6),
          const LinearProgressIndicator(),
        ],
      ),
      error: (e, _) => Text('Error al cargar categorías: $e'),
    );
  }
}

/// Selector de cuenta (opcional). Recuerda que sin cuenta el motor no
/// genera transacciones pendientes.
class _CampoCuenta extends StatelessWidget {
  const _CampoCuenta({
    required this.icon,
    required this.cuentasAsync,
    required this.cuentaId,
    required this.onChanged,
  });

  final IconData icon;
  final AsyncValue<List<Account>> cuentasAsync;
  final String? cuentaId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return cuentasAsync.when(
      data: (cuentas) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppFormDropdownField<String?>(
            icon: icon,
            label: 'Cuenta (opcional)',
            value: cuentaId,
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Sin cuenta asignada'),
              ),
              for (final cuenta in cuentas)
                DropdownMenuItem(value: cuenta.id, child: Text(cuenta.name)),
            ],
            onChanged: onChanged,
          ),
          const SizedBox(height: 6),
          Text(
            'Cuenta sugerida para el pago. Sin cuenta, no se generarán '
            'transacciones pendientes hasta que se asigne una.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppFieldLabel(icon: icon, label: 'Cuenta (opcional)'),
          const SizedBox(height: 6),
          const LinearProgressIndicator(),
        ],
      ),
      error: (e, _) => Text('Error al cargar cuentas: $e'),
    );
  }
}

/// Campo(s) de día de pago, exclusivos de cada frecuencia: un día del mes
/// (mensual), dos días del mes elegidos por el usuario (quincenal), un día
/// de la semana (semanal), o nada capturable (anual, se ancla a la fecha de
/// inicio).
class _CampoDiaDePago extends StatelessWidget {
  const _CampoDiaDePago({
    required this.frecuencia,
    required this.diaMesController,
    required this.diaQuincena1Controller,
    required this.diaQuincena2Controller,
    required this.diaSemana,
    required this.onDiaSemanaChanged,
  });

  final ObligationFrequency frecuencia;
  final TextEditingController diaMesController;
  final TextEditingController diaQuincena1Controller;
  final TextEditingController diaQuincena2Controller;
  final int diaSemana;
  final ValueChanged<int> onDiaSemanaChanged;

  String? _validarDiaDeMes(String? valor) {
    final dia = int.tryParse(valor ?? '');
    if (dia == null || dia < 1 || dia > 31) {
      return 'Ingresa un día entre 1 y 31.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    switch (frecuencia) {
      case ObligationFrequency.mensual:
        return AppFormTextField(
          icon: Icons.event_repeat_outlined,
          label: 'Día de Pago (1-31)',
          controller: diaMesController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: _validarDiaDeMes,
        );
      case ObligationFrequency.semanal:
        return AppFormDropdownField<int>(
          icon: Icons.event_repeat_outlined,
          label: 'Día de la Semana',
          value: diaSemana,
          items: [
            for (final entrada in _etiquetasDiaSemana.entries)
              DropdownMenuItem(value: entrada.key, child: Text(entrada.value)),
          ],
          onChanged: (valor) => onDiaSemanaChanged(valor!),
        );
      case ObligationFrequency.quincenal:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppFormTextField(
                icon: Icons.event_repeat_outlined,
                label: 'Primer Día (1-31)',
                controller: diaQuincena1Controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: _validarDiaDeMes,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppFormTextField(
                icon: Icons.event_repeat_outlined,
                label: 'Segundo Día (1-31)',
                controller: diaQuincena2Controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: _validarDiaDeMes,
              ),
            ),
          ],
        );
      case ObligationFrequency.anual:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppFieldLabel(
              icon: Icons.event_repeat_outlined,
              label: 'Día de Pago',
            ),
            const SizedBox(height: 6),
            Text(
              'Se paga una vez al año, en la fecha de inicio.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
    }
  }
}
