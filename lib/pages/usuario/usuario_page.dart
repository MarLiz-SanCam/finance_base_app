import 'package:flutter/material.dart';

import '../../core/components/app_showcase.dart';
import '../../core/components/appBar.dart';
import '../../core/showcase/showcase_keys.dart';

/// Mock de la futura pantalla de Usuario: todavía no tiene funcionalidad,
/// solo ocupa su lugar en la barra de navegación mientras se diseña.
/// [onHelp] abre el showcase (lo provee [RootShell]).
class UsuarioPage extends StatelessWidget {
  const UsuarioPage({super.key, this.onHelp});

  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppMainAppBar(title: 'Usuario', onHelp: onHelp),
      body: SafeArea(
        child: Center(
          child: AppShowcase(
            showcaseKey: ShowcaseKeys.usuarioInfo,
            title: 'Usuario',
            description:
                'Aquí vivirá tu perfil y la configuración de la app. Todavía estamos trabajando en esta sección.',
            borderRadius: 12,
            targetPadding: const EdgeInsets.all(12),
            child: Text(
              'Próximamente',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }
}
