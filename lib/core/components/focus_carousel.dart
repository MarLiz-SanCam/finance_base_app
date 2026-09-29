import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'page_indicator.dart';

/// Carrusel horizontal donde el ítem central ("enfocado") se dibuja más
/// grande que los de los lados, y se superpone a ellos.
///
/// Usa un [PageView] únicamente para el gesto de arrastre y el snap; los
/// ítems no viven dentro de él sino en un [Stack] propio, ordenado por
/// foco. Así el ítem central queda siempre por encima de sus vecinos (un
/// [PageView] pinta los ítems en orden de índice, y el vecino derecho
/// taparía al central).
///
/// [itemBuilder] recibe además el [focus] del ítem (1 = centrado, 0 = a una
/// página o más de distancia) para que la tarjeta pueda interpolar su
/// propia tipografía y sombra. El ítem ya llega con el tamaño que le toca:
/// el carrusel lo dimensiona entre `minScale` y 1.
///
/// Tocar un ítem lateral lo centra; tocar el central llama [onItemTap].
class AppFocusCarousel extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index, double focus)
  itemBuilder;
  final double height;

  /// Distancia entre centros de ítems contiguos, como fracción del ancho.
  final double viewportFraction;

  /// Ancho del ítem enfocado, como múltiplo de la distancia entre centros.
  /// Con un valor > 1 el ítem enfocado se traslapa con sus vecinos.
  final double itemWidthFactor;

  /// Tamaño de un ítem sin foco respecto al enfocado (0-1).
  final double minScale;

  final int initialPage;
  final ValueChanged<int>? onPageChanged;
  final ValueChanged<int>? onItemTap;
  final bool showIndicator;

  const AppFocusCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.height = 130,
    this.viewportFraction = 0.26,
    this.itemWidthFactor = 1.18,
    this.minScale = 0.85,
    this.initialPage = 0,
    this.onPageChanged,
    this.onItemTap,
    this.showIndicator = true,
  });

  @override
  State<AppFocusCarousel> createState() => _AppFocusCarouselState();
}

class _AppFocusCarouselState extends State<AppFocusCarousel> {
  late final PageController _controller;
  late int _currentPage;

  static const _animationDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _controller = PageController(
      initialPage: widget.initialPage,
      viewportFraction: widget.viewportFraction,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Posición fraccionaria del carrusel (2.0 = ítem 2 centrado). Antes del
  /// primer layout el controlador aún no tiene posición.
  double get _page => _controller.hasClients
      ? (_controller.page ?? widget.initialPage.toDouble())
      : widget.initialPage.toDouble();

  void _handleTap(double dx, double width) {
    final slot = width * widget.viewportFraction;
    final page = _page;

    // Del más al menos enfocado: el primero cuyo rectángulo contiene el
    // toque es el que se ve encima.
    final indices = _visibleIndices(page, width, slot)
      ..sort((a, b) => (a - page).abs().compareTo((b - page).abs()));
    for (final i in indices) {
      final scale = _scaleFor(_focusFor(i, page));
      final itemWidth = slot * widget.itemWidthFactor * scale;
      final center = width / 2 + (i - page) * slot;
      if (dx >= center - itemWidth / 2 && dx <= center + itemWidth / 2) {
        if (i == _currentPage) {
          widget.onItemTap?.call(i);
        } else {
          _controller.animateToPage(
            i,
            duration: _animationDuration,
            curve: Curves.easeOutCubic,
          );
        }
        return;
      }
    }
  }

  double _focusFor(int index, double page) =>
      (1 - (index - page).abs()).clamp(0.0, 1.0);

  double _scaleFor(double focus) =>
      widget.minScale + (1 - widget.minScale) * focus;

  List<int> _visibleIndices(double page, double width, double slot) {
    final reach = (width / slot / 2).ceil() + 1;
    final first = math.max(0, page.floor() - reach);
    final last = math.min(widget.itemCount - 1, page.ceil() + reach);
    return [for (var i = first; i <= last; i++) i];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == 0) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final slot = width * widget.viewportFraction;

              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp: (details) =>
                    _handleTap(details.localPosition.dx, width),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Solo aporta arrastre y snap; sus páginas están vacías.
                    Positioned.fill(
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: widget.itemCount,
                        onPageChanged: (i) {
                          setState(() => _currentPage = i);
                          widget.onPageChanged?.call(i);
                        },
                        itemBuilder: (context, index) => const SizedBox(),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) =>
                              _buildItems(context, width, slot),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (widget.showIndicator) ...[
          const SizedBox(height: 8),
          AppPageIndicator(count: widget.itemCount, index: _currentPage),
        ],
      ],
    );
  }

  Widget _buildItems(BuildContext context, double width, double slot) {
    final page = _page;
    // De menor a mayor foco: el enfocado se pinta al final (encima).
    final indices = _visibleIndices(page, width, slot)
      ..sort((a, b) => _focusFor(a, page).compareTo(_focusFor(b, page)));

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final i in indices)
          _buildItem(context, i, page, width: width, slot: slot),
      ],
    );
  }

  Widget _buildItem(
    BuildContext context,
    int index,
    double page, {
    required double width,
    required double slot,
  }) {
    final focus = _focusFor(index, page);
    final scale = _scaleFor(focus);
    final itemWidth = slot * widget.itemWidthFactor * scale;
    final itemHeight = widget.height * scale;
    final center = width / 2 + (index - page) * slot;

    return Positioned(
      key: ValueKey(index),
      left: center - itemWidth / 2,
      top: (widget.height - itemHeight) / 2,
      width: itemWidth,
      height: itemHeight,
      child: widget.itemBuilder(context, index, focus),
    );
  }
}
