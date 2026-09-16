import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

/// Alta o edición de una obligación (gasto fijo, progresivo o ingreso fijo).
/// `type` no se puede cambiar en edición (ver `ObligationsRepository`).
class FormObligacionPage extends ConsumerStatefulWidget {
  const FormObligacionPage({super.key, this.obligacionExistente});

  final Obligation? obligacionExistente;

  @override
  ConsumerState<FormObligacionPage> createState() => _FormObligacionPageState();
}

class _FormObligacionPageState extends ConsumerState<FormObligacionPage> {
  final _formKey = GlobalKey<FormState>();
  final _formatoFecha = DateFormat('dd/MM/yyyy');

  late final _conceptoController = TextEditingController(
    text: widget.obligacionExistente?.concept,
  );
  late final _montoController = TextEditingController(
    text: widget.obligacionExistente == null
        ? ''
        : (widget.obligacionExistente!.amountPerPeriod / 100).toStringAsFixed(
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
    super.dispose();
  }

  Future<void> _seleccionarFecha({
    required DateTime? actual,
    required ValueChanged<DateTime> onSeleccionada,
  }) async {
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: actual ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (seleccionada != null) onSeleccionada(seleccionada);
  }

  int? _diaPagoSeleccionado() {
    switch (_frecuencia) {
      case ObligationFrequency.mensual:
        return int.tryParse(_diaMesController.text);
      case ObligationFrequency.semanal:
        return _diaSemana;
      case ObligationFrequency.quincenal:
      case ObligationFrequency.anual:
        return null;
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
      final montoCentavos = Money.pesosACentavos(_montoController.text);
      final totalCentavos = _esProgresivo
          ? Money.pesosACentavos(_totalController.text)
          : null;
      final paymentDay = _diaPagoSeleccionado();

      if (_editando) {
        await repo.actualizar(
          id: widget.obligacionExistente!.id,
          concept: _conceptoController.text.trim(),
          categoryId: _categoriaId!,
          accountId: _cuentaId,
          frequency: _frecuencia,
          amountPerPeriodCentavos: montoCentavos,
          paymentDay: paymentDay,
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
          paymentDay: paymentDay,
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
    final categoriasAsync = ref.watch(
      categoriesByTypeStreamProvider(_tipoCategoriaEsperado),
    );
    final cuentasAsync = ref.watch(accountsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar obligación' : 'Nueva obligación'),
        actions: [
          if (_editando)
            IconButton(
              onPressed: _guardando ? null : _eliminar,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar obligación',
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
                  controller: _conceptoController,
                  autofocus: !_editando,
                  maxLength: 150,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Concepto',
                    hintText: 'Ej. Renta, Netflix, Préstamo laptop...',
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'El concepto es obligatorio.';
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
                  DropdownButtonFormField<ObligationType>(
                    initialValue: _tipo,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: [
                      for (final tipo in ObligationType.values)
                        DropdownMenuItem(
                          value: tipo,
                          child: Text(_etiquetasTipo[tipo]!),
                        ),
                    ],
                    onChanged: (valor) => setState(() {
                      _tipo = valor!;
                      _categoriaId = null;
                    }),
                  ),
                const SizedBox(height: 8),
                categoriasAsync.when(
                  data: (categorias) {
                    if (categorias.isEmpty) {
                      return Text(
                        'No hay categorías de tipo '
                        '${_tipoCategoriaEsperado == CategoryType.ingreso ? "ingreso" : "gasto"} '
                        'todavía. Crea una primero.',
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    }
                    if (_categoriaId != null &&
                        categorias.every((c) => c.id != _categoriaId)) {
                      _categoriaId = null;
                    }
                    return DropdownButtonFormField<String>(
                      initialValue: _categoriaId,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: [
                        for (final categoria in categorias)
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
                const SizedBox(height: 8),
                cuentasAsync.when(
                  data: (cuentas) => DropdownButtonFormField<String?>(
                    initialValue: _cuentaId,
                    decoration: const InputDecoration(
                      labelText: 'Cuenta (opcional)',
                      helperText:
                          'Cuenta sugerida para el pago. Sin cuenta, '
                          'no se generarán transacciones pendientes hasta '
                          'que se asigne una.',
                      helperMaxLines: 2,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Sin cuenta asignada'),
                      ),
                      for (final cuenta in cuentas)
                        DropdownMenuItem(
                          value: cuenta.id,
                          child: Text(cuenta.name),
                        ),
                    ],
                    onChanged: (valor) => setState(() => _cuentaId = valor),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error al cargar cuentas: $e'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ObligationFrequency>(
                  initialValue: _frecuencia,
                  decoration: const InputDecoration(labelText: 'Frecuencia'),
                  items: [
                    for (final frecuencia in ObligationFrequency.values)
                      DropdownMenuItem(
                        value: frecuencia,
                        child: Text(_etiquetasFrecuencia[frecuencia]!),
                      ),
                  ],
                  onChanged: (valor) => setState(() => _frecuencia = valor!),
                ),
                const SizedBox(height: 8),
                _CampoDiaDePago(
                  frecuencia: _frecuencia,
                  diaMesController: _diaMesController,
                  diaSemana: _diaSemana,
                  onDiaSemanaChanged: (valor) =>
                      setState(() => _diaSemana = valor),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _montoController,
                  decoration: InputDecoration(
                    labelText: _esProgresivo
                        ? 'Cuota por periodo'
                        : 'Monto por periodo',
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
                      return 'Monto inválido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _fechaInicioRequerida
                        ? 'Fecha de inicio'
                        : 'Fecha de inicio (opcional)',
                  ),
                  subtitle: Text(
                    _fechaInicio == null
                        ? 'Sin definir'
                        : _formatoFecha.format(_fechaInicio!),
                  ),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () => _seleccionarFecha(
                    actual: _fechaInicio,
                    onSeleccionada: (fecha) =>
                        setState(() => _fechaInicio = fecha),
                  ),
                ),
                if (_esProgresivo) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _totalController,
                    decoration: const InputDecoration(
                      labelText: 'Monto total de la deuda',
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
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Fecha de fin (opcional)'),
                    subtitle: Text(
                      _fechaFin == null
                          ? 'Sin definir'
                          : _formatoFecha.format(_fechaFin!),
                    ),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () => _seleccionarFecha(
                      actual: _fechaFin,
                      onSeleccionada: (fecha) =>
                          setState(() => _fechaFin = fecha),
                    ),
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

class _CampoDiaDePago extends StatelessWidget {
  const _CampoDiaDePago({
    required this.frecuencia,
    required this.diaMesController,
    required this.diaSemana,
    required this.onDiaSemanaChanged,
  });

  final ObligationFrequency frecuencia;
  final TextEditingController diaMesController;
  final int diaSemana;
  final ValueChanged<int> onDiaSemanaChanged;

  @override
  Widget build(BuildContext context) {
    switch (frecuencia) {
      case ObligationFrequency.mensual:
        return TextFormField(
          controller: diaMesController,
          decoration: const InputDecoration(labelText: 'Día de pago (1-31)'),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (valor) {
            final dia = int.tryParse(valor ?? '');
            if (dia == null || dia < 1 || dia > 31) {
              return 'Ingresa un día entre 1 y 31.';
            }
            return null;
          },
        );
      case ObligationFrequency.semanal:
        return DropdownButtonFormField<int>(
          initialValue: diaSemana,
          decoration: const InputDecoration(labelText: 'Día de la semana'),
          items: [
            for (final entrada in _etiquetasDiaSemana.entries)
              DropdownMenuItem(value: entrada.key, child: Text(entrada.value)),
          ],
          onChanged: (valor) => onDiaSemanaChanged(valor!),
        );
      case ObligationFrequency.quincenal:
        return Text(
          'Se paga los días 15 y el último día de cada mes.',
          style: Theme.of(context).textTheme.bodySmall,
        );
      case ObligationFrequency.anual:
        return Text(
          'Se paga una vez al año, en la fecha de inicio.',
          style: Theme.of(context).textTheme.bodySmall,
        );
    }
  }
}
