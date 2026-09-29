import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../showcase/showcase_keys.dart';

/// Paso del showcase con el estilo de la app y los botones en español. Todas
/// las pantallas lo usan en vez de [Showcase] para no repetir el estilo.
/// "Anterior"/"Listo" se deciden solos según [ShowcaseKeys.esPrimero] y
/// [ShowcaseKeys.esUltimo].
class AppShowcase extends StatelessWidget {
  const AppShowcase({
    super.key,
    required this.showcaseKey,
    required this.title,
    required this.description,
    required this.child,
    this.borderRadius = 16,
    this.targetPadding = EdgeInsets.zero,
    this.tooltipPosition,
  });

  final GlobalKey showcaseKey;
  final String title;
  final String description;
  final Widget child;
  final double borderRadius;
  final EdgeInsets targetPadding;
  final TooltipPosition? tooltipPosition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final esPrimero = ShowcaseKeys.esPrimero(showcaseKey);
    final esUltimo = ShowcaseKeys.esUltimo(showcaseKey);

    TooltipActionButton accion(
      TooltipDefaultActionType tipo,
      String nombre, {
      required bool principal,
    }) {
      return TooltipActionButton(
        type: tipo,
        name: nombre,
        backgroundColor: principal
            ? colorScheme.primary
            : colorScheme.primaryContainer,
        textStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: principal
              ? colorScheme.onPrimary
              : colorScheme.onPrimaryContainer,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      );
    }

    return Showcase(
      key: showcaseKey,
      title: title,
      description: description,
      tooltipPosition: tooltipPosition,
      targetPadding: targetPadding,
      targetBorderRadius: BorderRadius.circular(borderRadius),
      tooltipBackgroundColor: colorScheme.surface,
      textColor: colorScheme.onSurface,
      titleTextStyle: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
      descTextStyle: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface,
      ),
      tooltipBorderRadius: BorderRadius.circular(16),
      tooltipPadding: const EdgeInsets.all(12),
      overlayColor: Colors.black,
      overlayOpacity: 0.7,
      tooltipActionConfig: const TooltipActionConfig(
        alignment: MainAxisAlignment.end,
        actionGap: 8,
        gapBetweenContentAndAction: 12,
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
      tooltipActions: [
        if (!esPrimero)
          accion(
            TooltipDefaultActionType.previous,
            'Anterior',
            principal: false,
          ),
        if (!esUltimo)
          accion(TooltipDefaultActionType.skip, 'Omitir', principal: false),
        accion(
          TooltipDefaultActionType.next,
          esUltimo ? 'Listo' : 'Siguiente',
          principal: true,
        ),
      ],
      child: child,
    );
  }
}
