import 'package:flutter/material.dart';

import '../../core/components/appBar.dart';
import '../../core/components/pill_tab_bar.dart';
import '../../core/showcase/showcase_keys.dart';
import '../egresos/egresos_tab.dart';
import '../ingresos/ingresos_tab.dart';

/// Dashboard de Balance: tabs Gastos e Ingresos, se abre en Gastos por
/// defecto. [controller] vive en [RootShell] para que el botón central de
/// la barra de navegación sepa qué tab está activo.
class BalancePage extends StatelessWidget {
  const BalancePage({super.key, required this.controller, this.onHelp});

  final TabController controller;
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppMainAppBar(
        title: 'Balance',
        onHelp: onHelp,
        bottom: AppPillTabBar(
          controller: controller,
          tabs: const ['Gastos', 'Ingresos'],
          showcaseKey: ShowcaseKeys.balanceTabs,
          showcaseTitle: 'Gastos e ingresos',
          showcaseDescription:
              'Cambia entre tus gastos y tus ingresos. Cada sección tiene su propia ayuda.',
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: controller,
          children: const [EgresosTabContent(), IngresosTabContent()],
        ),
      ),
    );
  }
}
