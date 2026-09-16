import 'package:flutter/material.dart';

import 'form_ingresos.dart';
import 'widgets/grafico_ingresos.dart';
import 'widgets/resumen_ingresos_row.dart';
import 'widgets/tabla_ingresos.dart';

/// Dashboard de ingresos: total del mes + botón para agregar, tabla de
/// movimientos y gráfico histórico.
class DashIngresosPage extends StatelessWidget {
  const DashIngresosPage({super.key});

  void _abrirFormulario(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FormIngresoPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ingresos',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ResumenIngresosRow(
                onAgregar: () => _abrirFormulario(context),
              ),
              const SizedBox(height: 24),
              Text('Movimientos', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const TablaIngresos(),
              const SizedBox(height: 24),
              Text('Histórico', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const GraficoIngresos(),
            ],
          ),
        ),
      ),
    );
  }
}
