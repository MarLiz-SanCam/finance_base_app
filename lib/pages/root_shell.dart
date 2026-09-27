import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../core/components/bottomNavBar.dart';
import 'egresos/dash_egresos.dart';
import 'home.dart';
import 'ingresos/dash_ingresos.dart';

/// Cascarón de navegación: Egresos, Inicio e Ingresos, con una barra
/// inferior donde el ítem activo se expande a píldora con etiqueta. Cuentas,
/// Categorías y Obligaciones ya no viven en un tab "Más": se acceden desde
/// los 3 botones circulares del AppBar de cada dashboard
/// ([AppMainAppBar]).
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _indice = 1;

  static const _paginas = [
    DashEgresosPage(),
    HomePage(),
    DashIngresosPage(),
  ];

  static final  _items = [
    AppBottomNavItem(icon: Icons.trending_down, label: 'Egresos'),
    AppBottomNavItem(icon: MdiIcons.finance, label: 'Inicio'),
    AppBottomNavItem(icon: Icons.trending_up, label: 'Ingresos'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _indice, children: _paginas),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            heightFactor: 1,
            child: AppBottomNavBar(
              items: _items,
              currentIndex: _indice,
              onTap: (i) => setState(() => _indice = i),
            ),
          ),
        ),
      ),
    );
  }
}
