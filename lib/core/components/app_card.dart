import 'package:material_ui/material_ui.dart';

/// Tarjeta base de la app: superficie plana con borde fino y esquinas
/// suaves, sin sombra. Es el contenedor de las tarjetas de balance,
/// presupuesto y gráficos. Si se pasa [onTap] responde al toque con ripple.
///
/// [elevation] se conserva por compatibilidad (la tarjeta enfocada de
/// [AppFocusCarousel]): ya no dibuja sombra, solo oscurece un poco el borde.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double elevation;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
    this.elevation = 2,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: borderRadius,
        border: Border.all(
          color: Color.lerp(
            colorScheme.outlineVariant,
            colorScheme.onSurfaceVariant,
            ((elevation - 1) / 12).clamp(0.0, 0.3),
          )!,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
