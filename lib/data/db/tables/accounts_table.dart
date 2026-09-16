import 'package:drift/drift.dart';

import '../enums.dart';

/// 1. CATÁLOGOS BASE — Cuentas (efectivo, débito, crédito).
///
/// `current_balance` se guarda en centavos (ver [Money]) y se mantiene
/// derivado de las transacciones PAGADAS: no se edita a mano salvo para
/// fijar el saldo inicial de la cuenta.
///
/// `id` es un UUID generado en el cliente (no autoincrement): así un
/// registro creado sin conexión ya tiene una identidad global única, sin
/// coordinación con el servidor. `user_id`/`updated_at`/`deleted_at` son las
/// columnas de sincronización: dueño del registro, marca de tiempo para
/// resolver conflictos por última escritura, y tombstone de borrado suave
/// (nunca se hace DELETE real sobre estas filas, para que la eliminación se
/// pueda propagar a otros dispositivos).
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get type => textEnum<AccountType>()();
  IntColumn get currentBalance => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
