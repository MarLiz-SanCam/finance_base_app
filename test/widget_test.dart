import 'package:drift/native.dart';
import 'package:finance_base_app/data/db/app_database.dart';
import 'package:finance_base_app/main.dart';
import 'package:finance_base_app/providers/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  testWidgets('La app arranca y muestra la barra de navegación inferior', (
    WidgetTester tester,
  ) async {
    // Los gráficos usan DateFormat(..., 'es_MX'); sin esto lanzan
    // LocaleDataException al construirse.
    await initializeDateFormatting('es_MX');

    // BD en memoria: en `flutter test` no hay canales de plataforma para
    // resolver el directorio de documentos real. Se cierra explícitamente
    // dentro del test (ver abajo) en vez de dejar que la desconexión
    // automática de ProviderScope la cierre al final: `close()` programa un
    // Timer interno de limpieza que necesita un `pump` para disparar antes
    // de que el framework de pruebas verifique que no quedan timers vivos.
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // IndexedStack mantiene las tres páginas montadas a la vez, así que
    // cada título aparece tanto en el dashboard como en la barra inferior.
    expect(find.text('Inicio'), findsWidgets);
    expect(find.text('Egresos'), findsWidgets);
    expect(find.text('Ingresos'), findsWidgets);

    await db.close();
    await tester.pump(Duration.zero);
  });
}
