import 'package:drift/drift.dart';

import '../enums.dart';
import 'accounts_table.dart';
import 'categories_table.dart';
import 'obligations_table.dart';

/// 3. TRANSACCIONES — el día a día (ingresos, gastos variables) y las
/// cuentas por pagar/cobrar generadas por el motor de obligaciones.
///
/// `amount` siempre se guarda en centavos y en positivo; el signo con el
/// que afecta el saldo de la cuenta lo determina `type`.
///
/// Devengo vs. flujo: `due_date` es cuándo vence/se espera el movimiento;
/// `payment_date` es cuándo se pagó/cobró de verdad (NULL mientras está
/// `pendiente`). Solo las filas con `status = pagado` afectan
/// `accounts.current_balance` — ver `AccountsRepository.applyDelta` y
/// `TransactionsRepository.confirmarPago`. Una transacción registrada
/// directamente (gasto variable, ingreso único) nace `pagado` con
/// `due_date == payment_date`, exactamente como se comportaba antes.
///
/// `obligation_id` es NULL para gastos/ingresos variables, y tiene un valor
/// cuando la transacción es el pago/cobro (o la promesa de pago) de una
/// obligación. Ver [Accounts] para el porqué de `id` (UUID) y las columnas
/// de sincronización.
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get concept => text().withLength(min: 1, max: 150)();
  IntColumn get amount => integer()();
  DateTimeColumn get dueDate => dateTime()();
  DateTimeColumn get paymentDate => dateTime().nullable()();
  TextColumn get type => textEnum<TransactionType>()();
  TextColumn get status =>
      textEnum<TransactionStatus>().withDefault(
        Constant(TransactionStatus.pagado.name),
      )();

  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get obligationId => text()
      .nullable()
      .references(Obligations, #id, onDelete: KeyAction.setNull)();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
