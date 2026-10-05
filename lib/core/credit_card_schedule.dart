/// Fechas de una tarjeta de crédito a partir de sus días de corte y de pago
/// (día del mes, 1-31). Si el mes tiene menos días que el día configurado se
/// usa el último día del mes, igual que en `ObligationSchedule`.
class CreditCardSchedule {
  CreditCardSchedule._();

  /// Próxima fecha, hoy incluido, en que cae [dia] del mes.
  static DateTime proximaFecha(int dia, DateTime desde) {
    final hoy = DateTime(desde.year, desde.month, desde.day);
    final esteMes = _clampDiaDeMes(hoy.year, hoy.month, dia);
    if (!esteMes.isBefore(hoy)) return esteMes;
    return _clampDiaDeMes(hoy.year, hoy.month + 1, dia);
  }

  static DateTime _clampDiaDeMes(int year, int month, int day) {
    final ultimoDia = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day.clamp(1, ultimoDia));
  }

  /// Días naturales desde [desde] hasta [fecha] (0 = hoy).
  static int diasHasta(DateTime fecha, DateTime desde) {
    final hoy = DateTime(desde.year, desde.month, desde.day);
    return fecha.difference(hoy).inDays;
  }
}
