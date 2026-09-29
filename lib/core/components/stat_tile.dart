import 'package:flutter/material.dart';

/// Indicador compacto de una cifra con ícono direccional: ícono + etiqueta
/// en una línea y el [value] justo debajo, alineado con la etiqueta
/// ("↑ Ingresos / $ 000.00"). Con [trailing] opcional a la derecha (ej. un
/// círculo o mini-ícono de acento).
///
/// [color] pinta solo el ícono; etiqueta y valor conservan el color de
/// texto del tema.
class AppStatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final Widget? trailing;

  const AppStatTile({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.trailing,
  });

  static const _iconSize = 20.0;
  static const _iconGap = 2.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: _iconSize, color: color),
            const SizedBox(width: _iconGap),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: textColor,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: _iconSize + _iconGap),
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (trailing == null) return content;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: content),
        const SizedBox(width: 8),
        trailing!,
      ],
    );
  }
}
