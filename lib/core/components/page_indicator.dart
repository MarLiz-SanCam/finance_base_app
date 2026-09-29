import 'package:flutter/material.dart';

/// Indicador de página: la página activa es una píldora alargada y las
/// demás, puntos pequeños y tenues.
class AppPageIndicator extends StatelessWidget {
  final int count;
  final int index;

  const AppPageIndicator({super.key, required this.count, required this.index});

  static const _duration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: _duration,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: i == index ? 16 : 5,
            height: 4,
            decoration: BoxDecoration(
              color: i == index
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}
