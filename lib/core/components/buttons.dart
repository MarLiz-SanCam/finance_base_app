import 'package:flutter/material.dart';

/// Botón de acción principal: píldora (stadium) rellena con
/// [ColorScheme.primary], ícono opcional + etiqueta. Úsalo para la acción
/// principal de cada pantalla (guardar, registrar, confirmar).
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
  });

  static ButtonStyle _style(ColorScheme colorScheme) => FilledButton.styleFrom(
    backgroundColor: colorScheme.primary,
    foregroundColor: colorScheme.onPrimary,
    disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
    disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
    shape: const StadiumBorder(),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    textStyle: const TextStyle(fontWeight: FontWeight.w600),
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final button = icon == null
        ? FilledButton(
            onPressed: onPressed,
            style: _style(colorScheme),
            child: Text(label),
          )
        : FilledButton.icon(
            onPressed: onPressed,
            style: _style(colorScheme),
            icon: Icon(icon),
            label: Text(label),
          );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Botón de acción secundaria: píldora (stadium) tonal, con
/// [ColorScheme.primaryContainer] de fondo. Úsalo junto a [AppPrimaryButton]
/// para acciones de menor jerarquía (cancelar, alternativas).
class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
  });

  static ButtonStyle _style(ColorScheme colorScheme) => FilledButton.styleFrom(
    backgroundColor: colorScheme.primaryContainer,
    foregroundColor: colorScheme.onPrimaryContainer,
    disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
    disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
    shape: const StadiumBorder(),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    textStyle: const TextStyle(fontWeight: FontWeight.w600),
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final button = icon == null
        ? FilledButton(
            onPressed: onPressed,
            style: _style(colorScheme),
            child: Text(label),
          )
        : FilledButton.icon(
            onPressed: onPressed,
            style: _style(colorScheme),
            icon: Icon(icon),
            label: Text(label),
          );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Botón circular relleno, para accesos directos compactos. Su primer uso
/// es en [AppMainAppBar]; incluye su propio margen horizontal para poder
/// encadenar varios seguidos sin que el llamador agregue espaciadores.
class AppCircularIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double iconSize;

  const AppCircularIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: IconButton.filled(
        icon: Icon(icon),
        iconSize: iconSize,
        tooltip: tooltip,
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
