import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/components/app_showcase.dart';
import '../../core/components/appBar.dart';
import '../../core/config/theme.dart';
import '../../core/showcase/showcase_keys.dart';
import '../../providers/theme_providers.dart';

/// Pantalla de Usuario: por ahora solo aloja la configuración de apariencia
/// (paleta y modo claro/oscuro); el perfil llegará después.
/// [onHelp] abre el showcase (lo provee [RootShell]).
class UsuarioPage extends ConsumerWidget {
  const UsuarioPage({super.key, this.onHelp});

  final VoidCallback? onHelp;

  static const _nombresPaleta = {
    AppPalette.green: 'Verde',
    AppPalette.yellow: 'Amarillo',
    AppPalette.pink: 'Rosa',
    AppPalette.teal: 'Azul',
  };

  static const _nombresModo = {
    ThemeMode.system: 'Sistema',
    ThemeMode.light: 'Claro',
    ThemeMode.dark: 'Oscuro',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppMainAppBar(title: 'Usuario', onHelp: onHelp),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppShowcase(
              showcaseKey: ShowcaseKeys.usuarioInfo,
              title: 'Usuario',
              description:
                  'Aquí vivirá tu perfil y la configuración de la app. Por ahora puedes cambiar la apariencia.',
              borderRadius: 12,
              targetPadding: const EdgeInsets.all(12),
              child: Text('Apariencia', style: textTheme.displaySmall),
            ),
            const SizedBox(height: 16),
            Text('Paleta', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<AppPalette>(
              showSelectedIcon: false,
              segments: [
                for (final p in AppPalette.values)
                  ButtonSegment(value: p, label: Text(_nombresPaleta[p]!)),
              ],
              selected: {settings.palette},
              onSelectionChanged: (s) => controller.setPalette(s.first),
            ),
            const SizedBox(height: 20),
            Text('Modo', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: [
                for (final m in ThemeMode.values)
                  ButtonSegment(value: m, label: Text(_nombresModo[m]!)),
              ],
              selected: {settings.mode},
              onSelectionChanged: (s) => controller.setMode(s.first),
            ),
          ],
        ),
      ),
    );
  }
}
