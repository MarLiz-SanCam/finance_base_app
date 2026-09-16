import 'package:flutter/material.dart';
import 'package:nav_bar_circles/nav_bar_circles.dart';

import 'egresos/dash_egresos.dart';
import 'home.dart';
import 'ingresos/dash_ingresos.dart';

/// Cascarón de navegación: Egresos, Inicio e Ingresos con una barra
/// inferior de círculos. El orden de [_paginas] e [_items] deja Inicio en
/// el índice central, entre Egresos e Ingresos.
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

  static const _items = [
    PillNavItem(icon: Icons.trending_down, label: 'Egresos'),
    PillNavItem(icon: Icons.home_rounded, label: 'Inicio'),
    PillNavItem(icon: Icons.trending_up, label: 'Ingresos'),
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
            child: PillNavBar(
              items: _items,
              currentIndex: _indice,
              onTap: (i) => setState(() => _indice = i),
              theme: PillNavBarTheme(
                activeColor: Theme.of(context).colorScheme.primary,
                inactiveColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                activeIconColor: Theme.of(context).colorScheme.onPrimary,
                inactiveIconColor: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
