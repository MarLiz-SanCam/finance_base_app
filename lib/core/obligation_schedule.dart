import '../data/db/enums.dart';

/// Calcula las fechas en que una obligación recurrente debería generar un
/// movimiento, a partir de su frecuencia y su `payment_day`.
///
/// El esquema original solo tiene un campo `payment_day` (día del mes),
/// insuficiente por sí solo para `semanal`/`quincenal`/`anual`. Se adoptan
/// las siguientes convenciones, documentadas aquí porque no vienen
/// explícitas en el esquema:
/// - `mensual`: una ocurrencia al mes en `payment_day`. Si el mes tiene
///   menos días que `payment_day`, se usa el último día del mes.
/// - `quincenal`: dos ocurrencias al mes, día 15 y último día del mes
///   (convención de nómina quincenal). `payment_day` se ignora.
/// - `semanal`: `payment_day` se interpreta como día ISO de la semana
///   (1=lunes .. 7=domingo).
/// - `anual`: una ocurrencia al año, en el mes/día de `anclaAnual`
///   (normalmente `start_date` de la obligación).
class ObligationSchedule {
  ObligationSchedule._();

  static List<DateTime> ocurrenciasEnRango({
    required ObligationFrequency frequency,
    required int? paymentDay,
    required DateTime desde,
    required DateTime hasta,
    DateTime? anclaAnual,
  }) {
    if (hasta.isBefore(desde)) return const [];

    switch (frequency) {
      case ObligationFrequency.mensual:
        return _ocurrenciasMensuales(paymentDay ?? 1, desde, hasta);
      case ObligationFrequency.quincenal:
        return _ocurrenciasQuincenales(desde, hasta);
      case ObligationFrequency.semanal:
        return _ocurrenciasSemanales(
          paymentDay ?? DateTime.monday,
          desde,
          hasta,
        );
      case ObligationFrequency.anual:
        return _ocurrenciasAnuales(anclaAnual ?? desde, desde, hasta);
    }
  }

  static DateTime _soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _clampDiaDeMes(int year, int month, int day) {
    final ultimoDiaDelMes = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day.clamp(1, ultimoDiaDelMes));
  }

  static bool _dentroDeRango(DateTime fecha, DateTime desde, DateTime hasta) {
    final f = _soloFecha(fecha);
    return !f.isBefore(_soloFecha(desde)) && !f.isAfter(_soloFecha(hasta));
  }

  static List<DateTime> _ocurrenciasMensuales(
    int paymentDay,
    DateTime desde,
    DateTime hasta,
  ) {
    final ocurrencias = <DateTime>[];
    var cursor = DateTime(desde.year, desde.month);
    final limite = DateTime(hasta.year, hasta.month);
    while (!cursor.isAfter(limite)) {
      final fecha = _clampDiaDeMes(cursor.year, cursor.month, paymentDay);
      if (_dentroDeRango(fecha, desde, hasta)) ocurrencias.add(fecha);
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return ocurrencias;
  }

  static List<DateTime> _ocurrenciasQuincenales(
    DateTime desde,
    DateTime hasta,
  ) {
    final ocurrencias = <DateTime>[];
    var cursor = DateTime(desde.year, desde.month);
    final limite = DateTime(hasta.year, hasta.month);
    while (!cursor.isAfter(limite)) {
      final dia15 = DateTime(cursor.year, cursor.month, 15);
      final ultimoDia = _clampDiaDeMes(cursor.year, cursor.month, 31);
      for (final fecha in [dia15, ultimoDia]) {
        if (_dentroDeRango(fecha, desde, hasta)) ocurrencias.add(fecha);
      }
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return ocurrencias;
  }

  static List<DateTime> _ocurrenciasSemanales(
    int diaIso,
    DateTime desde,
    DateTime hasta,
  ) {
    final ocurrencias = <DateTime>[];
    var cursor = _soloFecha(desde);
    final limite = _soloFecha(hasta);
    while (cursor.weekday != diaIso && !cursor.isAfter(limite)) {
      cursor = cursor.add(const Duration(days: 1));
    }
    while (!cursor.isAfter(limite)) {
      ocurrencias.add(cursor);
      cursor = cursor.add(const Duration(days: 7));
    }
    return ocurrencias;
  }

  static List<DateTime> _ocurrenciasAnuales(
    DateTime ancla,
    DateTime desde,
    DateTime hasta,
  ) {
    final ocurrencias = <DateTime>[];
    for (var year = desde.year; year <= hasta.year; year++) {
      final fecha = _clampDiaDeMes(year, ancla.month, ancla.day);
      if (_dentroDeRango(fecha, desde, hasta)) ocurrencias.add(fecha);
    }
    return ocurrencias;
  }
}
