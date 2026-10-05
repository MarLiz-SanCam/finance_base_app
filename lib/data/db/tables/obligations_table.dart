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
  TextColumn get accountId => text().nullable().references(Accounts, #id)();
  TextColumn get type => textEnum<ObligationType>()();
  TextColumn get frequency => textEnum<ObligationFrequency>()();

  /// Monto por periodo, en centavos. Opcional: si la obligación no tiene un
  /// monto fijo (ej. la luz, que varía cada recibo), se deja en blanco. El
  /// motor genera la transacción `pendiente` correspondiente con `amount =
  /// 0` como marca de "todavía no se sabe cuánto es" — 0 nunca ocurre en
  /// una transacción real, así que es inequívoco — y
  /// `TransactionsRepository.confirmarPago` exige que se indique el monto
  /// real antes de poder confirmarla.
  IntColumn get amountPerPeriod => integer().nullable()();

  /// Día del mes (1-31) en que se paga. Para frecuencia `semanal` se
  /// interpreta como día ISO de la semana (1=lunes..7=domingo). Para
  /// `quincenal` es el primer día de pago del mes (ver `paymentDay2` para el
  /// segundo). Para `anual` se ignora: se usa el mes/día de `start_date`
  /// como aniversario.
  IntColumn get paymentDay => integer().nullable()();

  /// Segundo día del mes (1-31) en que se paga, exclusivo de la frecuencia
  /// `quincenal` (el usuario elige ambas fechas; ya no se asumen día 15 y
  /// último día de mes). Se ignora para el resto de las frecuencias.
  IntColumn get paymentDay2 => integer().nullable()();
  TextColumn get status => textEnum<ObligationStatus>().withDefault(
    Constant(ObligationStatus.activo.name),
  )();
  DateTimeColumn get lastGeneratedDate => dateTime().nullable()();

  // Campos exclusivos para el tipo 'progresivo' (créditos/préstamos).
  IntColumn get totalAmount => integer().nullable()();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (type <> 'progresivo' OR "
        "(total_amount IS NOT NULL AND start_date IS NOT NULL))",
  ];
}
