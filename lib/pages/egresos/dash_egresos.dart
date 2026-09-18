import 'package:flutter/material.dart';

import 'widgets/card_gastos_realizados.dart';
import 'widgets/card_proximos_a_vencer.dart';
import 'widgets/fila_desglose_gastos.dart';
import 'widgets/grafico_gastos.dart';
import 'widgets/header_resumen_egresos.dart';
import 'widgets/seccion_categorias_gasto.dart';

/// Dashboard de egresos: sin AppBar, el título vive dentro del body junto
/// con el resumen del período y el acceso rápido para registrar un gasto.
class DashEgresosPage extends StatelessWidget {
  const DashEgresosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              HeaderResumenEgresos(),
              SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: CardProximosAVencer()),
                  SizedBox(width: 12),
                  Expanded(child: CardGastosRealizados()),
                ],
              ),
              SizedBox(height: 24),
              FilaDesgloseGastos(),
              SizedBox(height: 24),
              SeccionCategoriasGasto(),
              SizedBox(height: 24),
              GraficoGastos(),
            ],
          ),
        ),
      ),
    );
  }
}
