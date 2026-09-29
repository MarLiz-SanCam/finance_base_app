import 'package:drift/drift.dart';

import '../enums.dart';

/// 1. CATÁLOGOS BASE — Categorías de ingreso/gasto.
///
/// `budget_limit` es el presupuesto asignado por quincena, en centavos (los
/// ingresos y el ritmo de gasto de la app son quincenales, así que ese es el
/// período de referencia, no el mes calendario). Un `budget_limit` de 0
/// significa "sin presupuesto asignado".
///
/// `color` es el ARGB (`Color.toARGB32()`) elegido al crear la categoría en
/// [FormCategoriaSheet]; se usa en cualquier vista que represente categorías
/// por color (ej. el gráfico de dona de gastos por categoría) para que cada
/// una se identifique siempre con el mismo tono, sin depender del orden en
/// que se dibuje.
///
/// Ver [Accounts] para el porqué de `id` (UUID) y las columnas de
/// sincronización (`user_id`, `updated_at`, `deleted_at`).
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get type => textEnum<CategoryType>()();
  IntColumn get budgetLimit => integer().withDefault(const Constant(0))();
  IntColumn get color =>
      integer().withDefault(const Constant(0xFF2A78D6))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
