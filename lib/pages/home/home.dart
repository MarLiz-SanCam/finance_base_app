import 'package:flutter/material.dart';

import '../../core/components/app_showcase.dart';
import '../../core/components/appBar.dart';
import '../../core/showcase/showcase_keys.dart';
import 'widgets/grafico_balance.dart';
import 'widgets/resumen_balance.dart';

/// Dashboard principal: balance de la quincena e histórico de ingresos vs.
/// egresos. [onHelp] abre el showcase de la pantalla (lo provee [RootShell]).
class HomePage extends StatelessWidget {
  const HomePage({super.key, this.onHelp});

  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppMainAppBar(title: 'Resumen', onHelp: onHelp),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppShowcase(
                showcaseKey: ShowcaseKeys.resumenBalance,
                title: 'Balance de la quincena',
                description:
                    'Aquí ves cuánto has ingresado y gastado en la quincena en curso, y la diferencia entre ambos. En verde vas a favor; en rojo, te pasaste.',
                borderRadius: 12,
                child: const ResumenBalance(),
              ),
              const SizedBox(height: 24),
              AppShowcase(
                showcaseKey: ShowcaseKeys.resumenGrafico,
                title: 'Ingresos y gastos',
                description:
                    'Compara cómo han evolucionado tus ingresos (verde) y tus egresos (rojo) en los últimos periodos.',
                borderRadius: 12,
                child: const GraficoBalance(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
