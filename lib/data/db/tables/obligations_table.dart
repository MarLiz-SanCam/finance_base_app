import 'package:drift/drift.dart';

import '../enums.dart';
import 'accounts_table.dart';
import 'categories_table.dart';

/// 2. OBLIGACIONES Y RECURRENCIAS — el motor de automatización: gastos
/// fijos, progresivos (créditos/préstamos) e ingresos fijos.
///
/// `total_amount`, `start_date` y `end_date` son exclusivos del tipo
/// `progresivo`; se exige a nivel de BD con un CHECK y se valida también en
/// el repositorio antes de insertar/actualizar.
///
/// `last_generated_date` es la marca de agua del motor: hasta qué fecha ya
/// se generaron transacciones `PENDIENTE` para esta obligación (ver
/// `ObligationsRepository.generarPagosPendientes`). Evita recalcular desde
/// `start_date` cada vez.
///
/// Todos los montos se guardan en centavos (ver [Money]). Ver [Accounts]
/// para el porqué de `id` (UUID) y las columnas de sincronización.
class Obligations extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get concept => text().withLength(min: 1, max: 150)();
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get accountId =>
      text().nullable().references(Accounts, #id)();
  TextColumn get type => textEnum<ObligationType>()();
  TextColumn get frequency => textEnum<ObligationFrequency>()();
  IntColumn get amountPerPeriod => integer()();

  /// Día del mes (1-31) en que se paga. Para frecuencia `semanal` se
  /// interpreta como día ISO de la semana (1=lunes..7=domingo). Para
  /// `anual` se ignora: se usa el mes/día de `start_date` como aniversario.
  IntColumn get paymentDay => integer().nullable()();
  TextColumn get status =>
      textEnum<ObligationStatus>().withDefault(
        Constant(ObligationStatus.activo.name),
      )();
  DateTimeColumn get lastGeneratedDate => dateTime().nullable()();

  // Campos exclusivos para el tipo 'progresivo' (créditos/préstamos).
  IntColumn get totalAmount => integer().nullable()();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (type <> 'progresivo' OR "
        "(total_amount IS NOT NULL AND start_date IS NOT NULL))",
  ];
}
