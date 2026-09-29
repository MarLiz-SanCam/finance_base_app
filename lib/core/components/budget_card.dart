import 'package:flutter/material.dart';

import 'amount_text.dart';
import 'app_card.dart';

/// Tarjeta de un presupuesto: nombre de la categoría y monto restante,
/// centrados. El monto va en verde si aún hay presupuesto y en rojo si se
/// excedió.
///
/// Pensada para [AppFocusCarousel]: [focus] (0-1) interpola tipografía y
/// sombra entre el estado "de lado" (0, compacto) y el "enfocado" (1,
/// tarjeta más grande y elevada). Fuera del carrusel se usa con el valor
/// por defecto (enfocada).
class AppBudgetCard extends StatelessWidget {
  final String name;
  final int remainingCentavos;
  final double focus;
  final VoidCallback? onTap;

  const AppBudgetCard({
    super.key,
    required this.name,
    required this.remainingCentavos,
    this.focus = 1,
    this.onTap,
  });

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      radius: 20,
      elevation: _lerp(1, 4, focus),
      onTap: onTap,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: _lerp(11, 16, focus),
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            AppAmountText(
              remainingCentavos,
              colorBySign: true,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: _lerp(14, 18, focus),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
