import 'package:drift/native.dart';
import 'package:finance_base_app/core/showcase/showcase_keys.dart';
import 'package:finance_base_app/data/db/app_database.dart';
import 'package:finance_base_app/data/repositories/showcase_progress_repository.dart';
import 'package:finance_base_app/main.dart';
import 'package:finance_base_app/providers/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

void main() {
  group('ShowcaseProgressRepository', () {
    late AppDatabase db;
    late ShowcaseProgressRepository repo;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = ShowcaseProgressRepository(db);
    });

    tearDown(() => db.close());

    test('no está visto hasta que se marca', () async {
      expect(await repo.fueVisto('resumen', 1), isFalse);
      await repo.marcarVisto('resumen', 1);
      expect(await repo.fueVisto('resumen', 1), isTrue);
    });

    test('una versión nueva vuelve a mostrarse; la anterior no', () async {
      await repo.marcarVisto('resumen', 1);
      expect(await repo.fueVisto('resumen', 2), isFalse);
      await repo.marcarVisto('resumen', 2);
      expect(await repo.fueVisto('resumen', 1), isTrue);
      expect(await repo.fueVisto('resumen', 2), isTrue);
    });

    test('cada pantalla se marca por separado', () async {
      await repo.marcarVisto('resumen', 1);
      expect(await repo.fueVisto('balanceGastos', 1), isFalse);
    });
  });

  group('ShowcaseKeys', () {
    test('toda pantalla termina en la barra de navegación', () {
      for (final pantalla in ShowcasePantalla.values) {
        expect(
          ShowcaseKeys.pasosDe(pantalla).last,
          ShowcaseKeys.barraNavegacion,
        );
      }
    });

    test('solo Usuario omite el botón central', () {
      for (final pantalla in ShowcasePantalla.values) {
        expect(
          ShowcaseKeys.pasosDe(pantalla).contains(ShowcaseKeys.botonCentral),
          pantalla != ShowcasePantalla.usuario,
        );
      }
    });

    test('no hay claves repetidas dentro de una pantalla', () {
      for (final pantalla in ShowcasePantalla.values) {
        final pasos = ShowcaseKeys.pasosDe(pantalla);
        expect(pasos.toSet().length, pasos.length);
      }
    });
  });

  testWidgets('el botón de ayuda abre el showcase de la pantalla activa', (
    tester,
  ) async {
    await initializeDateFormatting('es_MX');
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    // Todo marcado como visto: evita que el showcase arranque solo y deje
    // solo el arranque por el botón de ayuda.
    final repo = ShowcaseProgressRepository(db);
    // runAsync: drift usa I/O real, que dentro del reloj falso de
    // testWidgets nunca se resuelve.
    await tester.runAsync(() async {
      for (final p in ShowcasePantalla.values) {
        await repo.marcarVisto(p.id, p.version);
      }
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MyApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Balance de la quincena'), findsNothing);

    await tester.tap(find.byIcon(MdiIcons.helpCircleOutline).first);
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Balance de la quincena'), findsOneWidget);
    expect(find.text('Siguiente'), findsOneWidget);
    expect(find.text('Omitir'), findsOneWidget);
    // Primer paso: no hay "Anterior".
    expect(find.text('Anterior'), findsNothing);

    // Se desmonta el árbol para liberar los ticker del overlay antes de
    // cerrar la BD.
    await tester.pumpWidget(const SizedBox());
    await db.close();
    await tester.pump(Duration.zero);
  });
}
