import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/components/focus_carousel.dart';
import '../../../core/money.dart';
import '../../../providers/desglose_egresos_providers.dart';
import '../desglose/desglose_grupo_page.dart';
import '../desglose/grupo_gasto_ui.dart';

/// Tres tarjetas (Fijos, Progresivos, Variables) con el total gastado en
/// cada grupo durante la quincena actual, como carrusel: la tarjeta
/// central queda enfocada y las de los lados se ven más chicas. Tocar la
/// enfocada abre su desglose por categoría (ver [DesgloseGrupoPage]).
class FilaDesgloseGastos extends ConsumerWidget {
  const FilaDesgloseGastos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalesAsync = ref.watch(totalesPorGrupoProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Desglose de gastos', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        totalesAsync.when(
          data: (totales) => AppFocusCarousel(
            itemCount: GrupoGasto.values.length,
            height: 88,
            viewportFraction: 0.2,
            itemWidthFactor: 2.0,
            minScale: 0.7,
            itemBuilder: (context, index, focus) {
              final grupo = GrupoGasto.values[index];
              return _TarjetaGrupo(
                grupo: grupo,
                totalCentavos: totales[grupo] ?? 0,
                focus: focus,
              );
            },
            onItemTap: (index) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    DesgloseGrupoPage(grupo: GrupoGasto.values[index]),
              ),
            ),
          ),
          loading: () => const Center(child: LinearProgressIndicator()),
          error: (error, _) => Text(
            'Error al cargar el desglose: $error',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

/// [focus] (0-1) interpola el tamaño del contenido: sin esto, una tarjeta
/// lateral —achicada por el carrusel a través de `minScale`— desbordaría
/// (el ícono y los dos textos a tamaño fijo no caben en una caja más
/// chica), igual que ya resuelve [AppBudgetCard] para el carrusel de
/// presupuestos.
class _TarjetaGrupo extends StatelessWidget {
  const _TarjetaGrupo({
    required this.grupo,
    required this.totalCentavos,
    this.focus = 1,
  });

  final GrupoGasto grupo;
  final int totalCentavos;
  final double focus;

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      // Sin esto, el margen por defecto de Card (4 en cada lado) resta
      // espacio visible al traslape entre tarjetas que arma el carrusel:
      // el tamaño que el carrusel calcula es para la tarjeta completa, no
      // para el hueco que deja el margen.
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(_lerp(6, 12, focus)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              iconosGrupoGasto[grupo],
              size: _lerp(13, 18, focus),
              color: theme.colorScheme.onSurfaceVariant,
            ),
            Text(
              etiquetasGrupoGasto[grupo]!,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: _lerp(9, 12, focus),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              Money.centavosAPesos(totalCentavos),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: _lerp(11, 14, focus),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
