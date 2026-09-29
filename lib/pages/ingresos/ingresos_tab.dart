import 'package:flutter/material.dart';

import '../../core/components/app_showcase.dart';
import '../../core/showcase/showcase_keys.dart';
import 'widgets/header_resumen_ingresos.dart';

/// Contenido del tab "Ingresos" de Balance: total de la quincena y saldo
/// disponible en cada cuenta. Registrar un ingreso nuevo se dispara desde
/// el botón central de la barra de navegación.
class IngresosTabContent extends StatelessWidget {
  const IngresosTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppShowcase(
            showcaseKey: ShowcaseKeys.ingresosHeader,
            title: 'Ingresos de la quincena',
            description:
                'Total que has ingresado en la quincena en curso. Debajo ves el saldo disponible de cada una de tus cuentas; desliza para ver todas.',
            borderRadius: 12,
            child: const HeaderResumenIngresos(),
          ),
        ],
      ),
    );
  }
}
