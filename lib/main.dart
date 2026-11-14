import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/config/theme.dart';
import 'pages/root_shell.dart';
import 'providers/database_provider.dart';
import 'providers/theme_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Los gráficos formatean fechas con locale 'es_MX' (ver GraficoIngresos,
  // GraficoBalance); sin esto, `DateFormat(..., 'es_MX')` lanza
  // LocaleDataException la primera vez que se usa.
  await initializeDateFormatting('es_MX');
  final container = ProviderContainer();
  // El motor de obligaciones (genera las transacciones `pendiente` de las
  // obligaciones activas hasta el horizonte por defecto). No hay tareas en
  // background reales en una app local: se ejecuta una vez al iniciar,
  // antes de construir la UI, para que "próximos a vencer" ya tenga datos.
  await container.read(obligationsRepositoryProvider).generarPagosPendientes();
  // Paleta y modo guardados, cargados antes de la primera pantalla.
  await container.read(themeControllerProvider.notifier).load();
  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeControllerProvider);
    return MaterialApp(
      title: 'Finanzas',
      theme: AppTheme.themeFor(settings.palette, Brightness.light),
      darkTheme: AppTheme.themeFor(settings.palette, Brightness.dark),
      themeMode: settings.mode,
      home: const RootShell(),
    );
  }
}
