import 'package:material_ui/material_ui.dart';

/// Botón de acción principal: relleno plano de esquinas suaves, con
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
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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

/// Botón de acción secundaria: contorno fino, sin relleno. Úsalo junto a [AppPrimaryButton]
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

  static ButtonStyle _style(ColorScheme colorScheme) => OutlinedButton.styleFrom(
    foregroundColor: colorScheme.onSurface,
    disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
    side: BorderSide(color: colorScheme.outlineVariant),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    textStyle: const TextStyle(fontWeight: FontWeight.w600),
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final button = icon == null
        ? OutlinedButton(
            onPressed: onPressed,
            style: _style(colorScheme),
            child: Text(label),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            style: _style(colorScheme),
            icon: Icon(icon),
            label: Text(label),
          );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Botón circular sin relleno (solo ícono), para accesos directos compactos. Su primer uso
/// es en [AppMainAppBar]; incluye su propio margen horizontal para poder
/// encadenar varios seguidos sin que el llamador agregue espaciadores.
/// [size] fija el mismo ancho y alto (nunca un óvalo) para que todos los
/// botones circulares de la app —el de ayuda, el de acción contextual, el
/// de transferir, etc.— midan y se vean exactamente igual.
class AppCircularIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double iconSize;
  final double size;

  const AppCircularIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.iconSize = 22,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: IconButton(
        icon: Icon(icon),
        iconSize: iconSize,
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          shape: const CircleBorder(),
          fixedSize: Size.square(size),
        ),
      ),
    );
  }
}
