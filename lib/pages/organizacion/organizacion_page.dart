import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../core/components/app_showcase.dart';
import '../../core/components/appBar.dart';
import '../../core/components/buttons.dart';
import '../../core/components/pill_tab_bar.dart';
import '../../core/showcase/showcase_keys.dart';
import '../categorias/categorias_tab.dart';
import '../cuentas/cuentas_tab.dart';
import '../cuentas/form_transferencia.dart';
import '../obligaciones/obligaciones_tab.dart';

/// Dashboard de Organización: tabs Cuentas, Categorías y Obligaciones.
/// [controller] vive en [RootShell] para que el botón central de la barra
/// de navegación sepa qué tab está activo. El ícono de "Transferir entre
/// cuentas" del encabezado solo se muestra en el tab Cuentas.
class OrganizacionPage extends StatelessWidget {
  const OrganizacionPage({super.key, required this.controller, this.onHelp});

  final TabController controller;
  final VoidCallback? onHelp;

  static const _tabs = ['Cuentas', 'Categorías', 'Obligaciones'];

  void _transferirEntreCuentas(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FormTransferenciaPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppMainAppBar(
        title: 'Organización',
        onHelp: onHelp,
        trailing: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final esTabCuentas = controller.index == 0;
            return Opacity(
              opacity: esTabCuentas ? 1 : 0,
              child: IgnorePointer(
                ignoring: !esTabCuentas,
                child: AppShowcase(
                  showcaseKey: ShowcaseKeys.cuentasTransferir,
                  title: 'Transferir entre cuentas',
                  description:
                      'Mueve dinero de una de tus cuentas a otra. Solo aparece en este tab.',
                  borderRadius: 100,
                  child: AppCircularIconButton(
                    icon: MdiIcons.transfer,
                    tooltip: 'Transferir entre cuentas',
                    onPressed: () => _transferirEntreCuentas(context),
                  ),
                ),
              ),
            );
          },
        ),
        bottom: AppPillTabBar(
          controller: controller,
          tabs: _tabs,
          showcaseKey: ShowcaseKeys.orgTabs,
          showcaseTitle: 'Organiza tus finanzas',
          showcaseDescription:
              'Administra tus cuentas, categorías y obligaciones. Cada sección tiene su propia ayuda.',
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: controller,
          children: const [
            CuentasTabContent(),
            CategoriasTabContent(),
            ObligacionesTabContent(),
          ],
        ),
      ),
    );
  }
}
