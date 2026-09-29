import 'package:flutter/material.dart';

/// Tarjeta base de la app: superficie clara con esquinas muy redondeadas y
/// una sombra suave y difusa (sin el tinte de superficie de [Card]).
///
/// Es el contenedor de las tarjetas de balance, presupuesto y gráficos. Si se
/// pasa [onTap] la tarjeta responde al toque con ripple.
///
/// [elevation] no es la elevación de Material: solo controla qué tan grande
/// y desplazada se dibuja la sombra, para poder "levantar" una tarjeta (ej.
/// la enfocada en [AppFocusCarousel]).
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
    this.radius = 20,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8 + elevation * 4,
            offset: Offset(0, elevation * 1.25),
          ),
        ],
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
