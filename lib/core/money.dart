import 'package:intl/intl.dart';

/// Todas las cantidades monetarias se almacenan en la base de datos como
/// enteros que representan centavos (1/100 de la unidad monetaria), para
/// evitar los errores de redondeo de punto flotante que arrastraría `double`
/// en operaciones financieras repetidas a lo largo del tiempo.
///
/// Esta clase es la única puerta de entrada/salida entre centavos (BD) y la
/// representación decimal que ve el usuario (UI). Ningún otro archivo debe
/// hacer `* 100` o `/ 100` manualmente sobre un monto.
class Money {
  Money._();

  static final NumberFormat _formatoMoneda = NumberFormat.currency(
    locale: 'es_MX',
    symbol: r'$',
    decimalDigits: 2,
  );

  /// Convierte un texto ingresado por el usuario (ej. "150.50" o "1,234.56")
  /// a centavos, sin pasar por `double` para no arrastrar errores de
  /// redondeo binario.
  static int pesosACentavos(String texto) {
    final limpio = texto.trim().replaceAll(',', '');
    if (limpio.isEmpty) return 0;

    final negativo = limpio.startsWith('-');
    final sinSigno = negativo ? limpio.substring(1) : limpio;
    final partes = sinSigno.split('.');
    if (partes.length > 2) {
      throw FormatException('Monto inválido: $texto');
    }

    final enteros = partes[0].isEmpty ? '0' : partes[0];
    var decimales = partes.length == 2 ? partes[1] : '';
    if (decimales.length > 2) {
      decimales = decimales.substring(0, 2);
    }
    decimales = decimales.padRight(2, '0');

    if (!RegExp(r'^\d+$').hasMatch(enteros) ||
        !RegExp(r'^\d{2}$').hasMatch(decimales)) {
      throw FormatException('Monto inválido: $texto');
    }

    final centavos = int.parse(enteros) * 100 + int.parse(decimales);
    return negativo ? -centavos : centavos;
  }

  /// Convierte centavos a un texto legible con formato de moneda,
  /// ej. `1550` -> "$15.50".
  static String centavosAPesos(int centavos) {
    return _formatoMoneda.format(centavos / 100);
  }

  /// Convierte centavos a un `double` de solo lectura, útil exclusivamente
  /// para cálculos de presentación que NO se vuelven a guardar (ej.
  /// porcentajes de presupuesto usado, valores para gráficas). El resultado
  /// nunca debe volver a escribirse en la base de datos.
  static double centavosADoublePresentacion(int centavos) => centavos / 100;
}
