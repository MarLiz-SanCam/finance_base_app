import 'package:flutter/material.dart';

import '../core/components/appBar.dart';
import 'home/widgets/grafico_balance.dart';
import 'home/widgets/presupuesto_periodo.dart';
import 'home/widgets/registro_rapido_gasto.dart';
import 'home/widgets/resumen_balance.dart';

/// Dashboard principal: balance del mes, presupuesto, registro rápido de un
/// gasto variable e histórico de ingresos vs. egresos.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppMainAppBar(title: 'Inicio'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ResumenBalance(),
              const SizedBox(height: 16),
              const PresupuestoPeriodo(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => mostrarRegistroRapidoDeGasto(context),
                  icon: const Icon(Icons.bolt),
                  label: const Text('Registrar gasto rápido'),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Ingresos y gastos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const GraficoBalance(),
            ],
          ),
        ),
      ),
    );
  }
}
