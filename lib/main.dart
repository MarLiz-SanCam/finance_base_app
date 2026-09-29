import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/config/theme.dart';
import 'pages/root_shell.dart';
import 'providers/database_provider.dart';

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
  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Paleta provisional (deepPurple): el tema principal de AppTheme
    // todavía no se usa por sus colores, pero sí por su tipografía —
    // fontFamily y el TextTheme (h1/h2/h3/body/...) ya definidos ahí, para
    // que todo el texto de la app sea consistente en cuanto se confirme la
    // paleta definitiva.
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.deepPurple);
    return MaterialApp(
      title: 'Finanzas',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        fontFamily: 'Plus Jakarta Sans',
        textTheme: AppTheme.textThemeFor(colorScheme.onSurface),
      ),
      home: const RootShell(),
    );
  }
}
