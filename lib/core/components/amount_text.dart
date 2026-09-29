import 'package:flutter/material.dart';

import '../money.dart';

/// Monto en centavos con formato de moneda ([Money.centavosAPesos]), una
/// sola línea. Con [colorBySign] se pinta en verde si es >= 0 y en rojo si
/// es negativo; un [color] explícito tiene prioridad.
///
/// Sin [style] usa `bodyLarge`; los llamadores pasan el tamaño/peso según
/// el contexto (monto principal del balance, monto de una tarjeta, etc.).
class AppAmountText extends StatelessWidget {
  final int centavos;
  final TextStyle? style;
  final Color? color;
  final bool colorBySign;
  final TextAlign? textAlign;

  const AppAmountText(
    this.centavos, {
    super.key,
    this.style,
    this.color,
    this.colorBySign = false,
    this.textAlign,
  });

  /// Color de un monto positivo (ingresos, saldo a favor).
  ///
  /// Los colores semánticos de monto viven solo aquí y hoy salen del
  /// [ColorScheme] (`primary` / `error`); cuando se defina la paleta de
  /// alertas pendiente en theme.dart basta con cambiarlos en este punto.
  static Color positive(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  /// Color de un monto negativo (egresos, saldo en contra).
  static Color negative(BuildContext context) =>
      Theme.of(context).colorScheme.error;

  /// [positive] si [centavos] >= 0, [negative] si no.
  static Color forSign(BuildContext context, int centavos) =>
      centavos >= 0 ? positive(context) : negative(context);

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.bodyLarge;
    final resolved = color ?? (colorBySign ? forSign(context, centavos) : null);

    return Text(
      Money.centavosAPesos(centavos),
      style: resolved == null ? base : base?.copyWith(color: resolved),
      textAlign: textAlign,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
