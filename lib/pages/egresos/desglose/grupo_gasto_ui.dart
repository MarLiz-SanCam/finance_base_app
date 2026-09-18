import 'package:flutter/material.dart';

import '../../../providers/desglose_egresos_providers.dart';

/// Etiquetas e íconos de [GrupoGasto], compartidos entre la tarjeta del
/// dashboard y las pantallas de desglose (nivel 2 y 3), para que no se
/// desincronicen entre archivos.
const etiquetasGrupoGasto = {
  GrupoGasto.fijo: 'Gastos fijos',
  GrupoGasto.progresivo: 'Progresivos',
  GrupoGasto.variable: 'Gastos variables',
};

const iconosGrupoGasto = {
  GrupoGasto.fijo: Icons.event_repeat_outlined,
  GrupoGasto.progresivo: Icons.credit_card_outlined,
  GrupoGasto.variable: Icons.shopping_bag_outlined,
};
