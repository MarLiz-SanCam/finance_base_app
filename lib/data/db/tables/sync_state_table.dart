import 'package:drift/drift.dart';

/// Cursor de sincronización por tabla. Vive solo en el dispositivo, nunca se
/// sincroniza. `last_synced_rev` es la revisión monótona que asigna el
/// backend (no un timestamp de cliente) — evita que un reloj de dispositivo
/// desajustado haga perder u omitir cambios al hacer `pull`. Sin backend
/// real todavía, esta tabla queda lista pero sin usarse.
class SyncState extends Table {
  TextColumn get entityTable => text()();
  IntColumn get lastSyncedRev => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {entityTable};
}
