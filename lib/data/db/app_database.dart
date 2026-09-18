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
  int get schemaVersion => 4;

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
      // Sin usuarios reales todavía, se recrea el esquema en vez de migrar
      // datos de desarrollo.
      for (final tabla in ['accounts', 'categories', 'obligations', 'transactions']) {
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
