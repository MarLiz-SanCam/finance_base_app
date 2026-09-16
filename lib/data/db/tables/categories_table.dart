import 'package:drift/drift.dart';

import '../enums.dart';

/// 1. CATÁLOGOS BASE — Categorías de ingreso/gasto.
///
/// `budget_limit` es el presupuesto mensual asignado, en centavos. Un
/// `budget_limit` de 0 significa "sin presupuesto asignado".
///
/// Ver [Accounts] para el porqué de `id` (UUID) y las columnas de
/// sincronización (`user_id`, `updated_at`, `deleted_at`).
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get type => textEnum<CategoryType>()();
  IntColumn get budgetLimit => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
