import 'package:flutter/material.dart';

import 'app_showcase.dart';

/// Barra de tabs en forma de píldora: el tab activo se resalta con un
/// fondo redondeado (mismo lenguaje visual que [AppBottomNavBar]); los
/// inactivos quedan en texto plano. Se usa como `bottom` de
/// [AppMainAppBar] en pantallas con secciones (Balance, Organización).
///
/// Si se pasa [showcaseKey], la barra es un paso del showcase de la
/// pantalla con [showcaseTitle] y [showcaseDescription].
class AppPillTabBar extends StatelessWidget implements PreferredSizeWidget {
  final List<String> tabs;
  final TabController? controller;
  final GlobalKey? showcaseKey;
  final String? showcaseTitle;
  final String? showcaseDescription;

  const AppPillTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.showcaseKey,
    this.showcaseTitle,
    this.showcaseDescription,
  }) : assert(
         showcaseKey == null ||
             (showcaseTitle != null && showcaseDescription != null),
       );

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final tabBar = TabBar(
      controller: controller,
      tabs: [for (final texto in tabs) Tab(text: texto)],
      indicator: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorAnimation: TabIndicatorAnimation.elastic,
      dividerColor: Colors.transparent,
      labelColor: colorScheme.onPrimaryContainer,
      unselectedLabelColor: colorScheme.onSurfaceVariant,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      splashBorderRadius: BorderRadius.circular(999),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: showcaseKey == null
          ? tabBar
          : AppShowcase(
              showcaseKey: showcaseKey!,
              title: showcaseTitle!,
              description: showcaseDescription!,
              borderRadius: 999,
              child: tabBar,
            ),
    );
  }
}
