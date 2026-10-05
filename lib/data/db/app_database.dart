import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'enums.dart';
import 'tables/accounts_table.dart';
import 'tables/categories_table.dart';
import 'tables/local_settings_table.dart';
import 'tables/obligations_table.dart';
import 'tables/sync_state_table.dart';
import 'tables/transactions_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Accounts,
    Categories,
    Obligations,
    Transactions,
    LocalSettings,
    SyncState,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Permite inyectar un `QueryExecutor` en memoria (o cualquier otro) para
  /// pruebas unitarias de los repositorios, sin tocar el archivo real.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v1 -> v2: IDs pasan de INTEGER autoincrement a UUID, se agregan
      // columnas de sincronización (user_id/updated_at/deleted_at) y el
      // motor de obligaciones (status/due_date/payment_date en
      // transactions, last_generated_date en obligations).
      // v2 -> v3: obligations.amount_per_period pasa a opcional (montos
      // variables, ej. la luz).
      // v3 -> v4: nuevo TransactionType.transferencia para movimientos entre
      // cuentas propias; transactions.category_id pasa a opcional y se
      // agrega transactions.destination_account_id.
      // v4 -> v5: algunas instalaciones de desarrollo quedaron con
      // user_version = 4 pero sin destination_account_id (la migración
      // 3->4 no llegó a correr antes de que se agregara la columna), lo
      // que rompía cualquier SELECT sobre transactions con "no such
      // column: transactions.destination_account_id". Se vuelve a forzar
      // la recreación para dejar el esquema real al día.
      // v5 -> v6: obligations.payment_day_2 para que las obligaciones
      // quincenales usen dos fechas de pago elegidas por el usuario en vez
      // de asumir día 15 y último día de mes; categories.budget_limit pasa
      // a interpretarse como presupuesto por quincena (antes mensual), sin
      // cambio de esquema.
      // v6 -> v7: categories.color (ARGB elegido al crear la categoría),
      // para que el color de cada categoría sea fijo en vez de asignarse
      // según el orden de aparición en cada vista.
      // v7 -> v8: accounts.credit_limit (límite de crédito, nullable) para
      // las cuentas de tipo crédito. Se agrega la columna sin perder datos.
      // v8 -> v9: accounts.statement_day y accounts.payment_due_day (día de
      // corte y día límite de pago de las tarjetas de crédito).
      // Sin usuarios reales todavía, para versiones anteriores a 7 se
      // recrea el esquema en vez de migrar datos de desarrollo.
      if (from >= 7) {
        if (from < 8) await m.addColumn(accounts, accounts.creditLimit);
        await m.addColumn(accounts, accounts.statementDay);
        await m.addColumn(accounts, accounts.paymentDueDay);
        return;
      }
      for (final tabla in [
        'accounts',
        'categories',
        'obligations',
        'transactions',
      ]) {
        await m.deleteTable(tabla);
      }
      await m.createAll();
    },
    beforeOpen: (details) async {
      // SQLite trae las foreign keys desactivadas por defecto; sin esto,
      // los ON DELETE SET NULL y las referencias no se respetarían.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'finance_base_app');
  }
}
