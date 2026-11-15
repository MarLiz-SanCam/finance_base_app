import 'package:material_ui/material_ui.dart';

import 'app_showcase.dart';

/// Barra de tabs minimalista: el tab activo va en negrita con un subrayado
/// fino; los inactivos quedan en texto atenuado. Se usa como `bottom` de
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
  Size get preferredSize => const Size.fromHeight(46);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final tabBar = TabBar(
      controller: controller,
      tabs: [for (final texto in tabs) Tab(text: texto)],
      indicatorColor: colorScheme.onSurface,
      indicatorWeight: 2,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: colorScheme.outlineVariant,
      labelColor: colorScheme.onSurface,
      unselectedLabelColor: colorScheme.onSurfaceVariant,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: showcaseKey == null
          ? tabBar
          : AppShowcase(
              showcaseKey: showcaseKey!,
              title: showcaseTitle!,
              description: showcaseDescription!,
              borderRadius: 8,
              child: tabBar,
            ),
    );
  }
}
