import 'package:flutter/material.dart';

/// Paleta curada para el selector de color de categorías: variedad
/// suficiente para distinguir muchas categorías a simple vista sin
/// depender de un paquete externo. Los primeros 8 tonos son los mismos
/// (y en el mismo orden) que usa el gráfico de dona de gastos por
/// categoría cuando una categoría todavía no tiene color propio.
const List<Color> appCategoryColors = [
  Color(0xFF2A78D6), // azul
  Color(0xFFEB6834), // naranja
  Color(0xFF1BAF7A), // aqua
  Color(0xFFEDA100), // amarillo
  Color(0xFFE87BA4), // magenta
  Color(0xFF008300), // verde
  Color(0xFF4A3AA7), // violeta
  Color(0xFFE34948), // rojo
  Color(0xFF8D6E63), // café
  Color(0xFF00838F), // teal
  Color(0xFF5C6BC0), // índigo
  Color(0xFFEC407A), // rosa
  Color(0xFF9E9D24), // oliva
  Color(0xFF6D4C41), // marrón oscuro
  Color(0xFF546E7A), // gris azulado
  Color(0xFFAB47BC), // púrpura
];

/// Grilla de swatches circulares para elegir un color de una paleta fija;
/// el seleccionado se marca con un aro y una palomita.
class AppColorPicker extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onChanged;
  final List<Color> colors;

  const AppColorPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.colors = appCategoryColors,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final color in colors)
          _Swatch(
            color: color,
            selected: color.toARGB32() == selected.toARGB32(),
            onTap: () => onChanged(color),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: selected
              ? Border.all(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 2,
                )
              : null,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: selected
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : null,
        ),
      ),
    );
  }
}
