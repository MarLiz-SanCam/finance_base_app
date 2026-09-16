/// Período por defecto del dashboard de egresos: la quincena en curso.
///
/// Es una convención de visualización (días 1-15 / 16-fin de mes),
/// independiente de la convención de pago quincenal usada en
/// `ObligationSchedule` (que fija los pagos en día 15 y último día del mes).
class PeriodoQuincenal {
  const PeriodoQuincenal({
    required this.inicio,
    required this.finExclusivo,
    required this.numero,
  });

  /// Primer día del período (inclusive).
  final DateTime inicio;

  /// Primer día que ya NO pertenece al período (límite exclusivo), listo
  /// para usarse en consultas `isSmallerThanValue`.
  final DateTime finExclusivo;

  /// 1 = primera quincena (1-15), 2 = segunda quincena (16-fin de mes).
  final int numero;

  static PeriodoQuincenal actual([DateTime? ahora]) {
    final hoy = ahora ?? DateTime.now();
    if (hoy.day <= 15) {
      return PeriodoQuincenal(
        inicio: DateTime(hoy.year, hoy.month, 1),
        finExclusivo: DateTime(hoy.year, hoy.month, 16),
        numero: 1,
      );
    }
    return PeriodoQuincenal(
      inicio: DateTime(hoy.year, hoy.month, 16),
      finExclusivo: DateTime(hoy.year, hoy.month + 1, 1),
      numero: 2,
    );
  }

  DateTime get ultimoDia => finExclusivo.subtract(const Duration(days: 1));

  String etiqueta() {
    final mes = _meses[inicio.month - 1];
    return numero == 1 ? '1–15 $mes' : '16–${ultimoDia.day} $mes';
  }

  static const _meses = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
}
