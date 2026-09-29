import 'package:flutter/material.dart';

/// Cuerpo de la pantalla con las esquinas inferiores redondeadas, como una
/// "hoja" clara apoyada sobre el fondo oscuro donde vive la barra de
/// navegación inferior.
///
/// Se usa como `body` de un Scaffold cuyo `backgroundColor` es el color
/// oscuro (ej. `colorScheme.inverseSurface`): el contenido se recorta con
/// [radius] abajo y se pinta con el fondo normal del tema ([color] por
/// defecto es `scaffoldBackgroundColor`).
class AppRoundedBody extends StatelessWidget {
  final Widget child;
  final double radius;
  final Color? color;

  const AppRoundedBody({
    super.key,
    required this.child,
    this.radius = 50,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
      child: ColoredBox(
        color: color ?? Theme.of(context).scaffoldBackgroundColor,
        child: child,
      ),
    );
  }
}
