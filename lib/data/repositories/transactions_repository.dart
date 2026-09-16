import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../db/enums.dart';
import 'accounts_repository.dart';
import 'local_identity_repository.dart';
import 'obligations_repository.dart';

class TransactionsRepository {
  TransactionsRepository(this._db, this._accounts, this._obligations, this._identity);

  final AppDatabase _db;
  final AccountsRepository _accounts;
  final ObligationsRepository _obligations;
  final LocalIdentityRepository _identity;

  int _delta(TransactionType type, int amount) =>
      type == TransactionType.ingreso ? amount : -amount;

  /// Todas las transacciones no borradas (cualquier estado), más recientes
  /// primero por `due_date`.
  Stream<List<Transaction>> watchAll() {
    return (_db.select(_db.transactions)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.dueDate)]))
        .watch();
  }

  Stream<List<Transaction>> watchByAccount(String accountId) {
    return (_db.select(_db.transactions)
          ..where((t) => t.accountId.equals(accountId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.dueDate)]))
        .watch();
  }

  Stream<List<Transaction>> watchByObligation(String obligationId) {
    return (_db.select(_db.transactions)
          ..where(
            (t) => t.obligationId.equals(obligationId) & t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.dueDate)]))
        .watch();
  }

  /// Transacciones **pagadas** (dinero que ya se movió de verdad) de un
  /// tipo, más recientes primero por `payment_date`. Es la fuente para
  /// totales/tablas/gráficos de movimientos "realizados" — nunca incluye
  /// `pendiente` ni `cancelado`.
  Stream<List<Transaction>> watchByType(TransactionType type) {
    return (_db.select(_db.transactions)
          ..where(
            (t) =>
                t.type.equalsValue(type) &
                t.status.equalsValue(TransactionStatus.pagado) &
                t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.paymentDate)]))
        .watch();
  }

  /// Transacciones `pendiente` (generadas por el motor de obligaciones,
  /// todavía sin confirmar), próximas primero por `due_date`. Base de
  /// "cuentas por pagar/cobrar" en la UI.
  Stream<List<Transaction>> watchPendientes({TransactionType? type}) {
    return (_db.select(_db.transactions)
          ..where(
            (t) =>
                t.status.equalsValue(TransactionStatus.pendiente) &
                t.deletedAt.isNull() &
                (type == null
                    ? const Constant(true)
                    : t.type.equalsValue(type)),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
        .watch();
  }

  /// Verifica que el tipo de la categoría (ingreso/gasto) coincida con el
  /// tipo de la transacción, para no registrar p.ej. un gasto contra una
  /// categoría de ingresos.
  Future<void> _validarCategoria(String categoryId, TransactionType type) async {
    final categoria = await (_db.select(
      _db.categories,
    )..where((c) => c.id.equals(categoryId))).getSingle();
    if (categoria.type.name != type.name) {
      throw ArgumentError(
        'La categoría "${categoria.name}" es de tipo ${categoria.type.name} '
        'y no coincide con el tipo de transacción ${type.name}.',
      );
    }
  }

  /// Registra un movimiento directo (gasto variable, ingreso único): nace
  /// `pagado` con `due_date == payment_date == fecha` y afecta el saldo de
  /// inmediato, de forma atómica.
  Future<String> registrar({
    required String concept,
    required int amountCentavos,
    required DateTime fecha,
    required TransactionType type,
    required String accountId,
    required String categoryId,
  }) async {
    if (amountCentavos <= 0) {
      throw ArgumentError('El monto debe ser mayor a cero.');
    }
    await _validarCategoria(categoryId, type);

    final id = const Uuid().v7();
    final userId = await _identity.obtenerUserId();
    final ahora = DateTime.now();

    await _db.transaction(() async {
      await _db.into(_db.transactions).insert(
        TransactionsCompanion.insert(
          id: id,
          userId: userId,
          concept: concept,
          amount: amountCentavos,
          dueDate: fecha,
          paymentDate: Value(fecha),
          type: type,
          status: const Value(TransactionStatus.pagado),
          accountId: accountId,
          categoryId: categoryId,
          createdAt: Value(ahora),
          updatedAt: Value(ahora),
        ),
      );
      await _accounts.applyDelta(accountId, _delta(type, amountCentavos));
    });
    return id;
  }

  /// Confirma una transacción `pendiente` (generada por el motor de
  /// obligaciones): pasa a `pagado`, fija `payment_date` y recién entonces
  /// afecta el saldo. Si está vinculada a una obligación progresiva que
  /// llega a saldo 0, la marca finalizada.
  Future<void> confirmarPago(String transactionId, {DateTime? fecha}) async {
    await _db.transaction(() async {
      final transaccion = await (_db.select(
        _db.transactions,
      )..where((t) => t.id.equals(transactionId))).getSingle();
      if (transaccion.status != TransactionStatus.pendiente) {
        throw StateError(
          'Solo se puede confirmar una transacción pendiente (estado actual: '
          '${transaccion.status.name}).',
        );
      }

      final fechaPago = fecha ?? DateTime.now();
      await (_db.update(_db.transactions)..where((t) => t.id.equals(transactionId)))
          .write(
        TransactionsCompanion(
          status: const Value(TransactionStatus.pagado),
          paymentDate: Value(fechaPago),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await _accounts.applyDelta(
        transaccion.accountId,
        _delta(transaccion.type, transaccion.amount),
      );

      final obligationId = transaccion.obligationId;
      if (obligationId != null) {
        await _obligations.finalizarSiCorresponde(obligationId);
      }
    });
  }

  /// Descarta una transacción `pendiente` sin pagarla (p.ej. "este mes no
  /// se cobró Netflix"): pasa a `cancelado`, nunca afecta el saldo, y la
  /// fila se conserva para auditoría en vez de borrarse.
  Future<void> cancelarPago(String transactionId) async {
    final transaccion = await (_db.select(
      _db.transactions,
    )..where((t) => t.id.equals(transactionId))).getSingle();
    if (transaccion.status != TransactionStatus.pendiente) {
      throw StateError(
        'Solo se puede cancelar una transacción pendiente (estado actual: '
        '${transaccion.status.name}).',
      );
    }
    await (_db.update(_db.transactions)..where((t) => t.id.equals(transactionId)))
        .write(
      TransactionsCompanion(
        status: const Value(TransactionStatus.cancelado),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Actualiza una transacción ya `pagada`, revirtiendo su efecto anterior
  /// sobre el saldo (de la cuenta que tenía antes) y aplicando el nuevo, de
  /// forma atómica. Soporta que el usuario haya cambiado la cuenta,
  /// categoría, monto, fecha o tipo.
  Future<void> actualizar({
    required String id,
    required String concept,
    required int amountCentavos,
    required DateTime fecha,
    required TransactionType type,
    required String accountId,
    required String categoryId,
  }) async {
    if (amountCentavos <= 0) {
      throw ArgumentError('El monto debe ser mayor a cero.');
    }
    await _validarCategoria(categoryId, type);

    await _db.transaction(() async {
      final anterior = await (_db.select(
        _db.transactions,
      )..where((t) => t.id.equals(id))).getSingle();

      await (_db.update(_db.transactions)..where((t) => t.id.equals(id)))
          .write(
        TransactionsCompanion(
          concept: Value(concept),
          amount: Value(amountCentavos),
          dueDate: Value(fecha),
          paymentDate: anterior.status == TransactionStatus.pagado
              ? Value(fecha)
              : const Value.absent(),
          type: Value(type),
          accountId: Value(accountId),
          categoryId: Value(categoryId),
          updatedAt: Value(DateTime.now()),
        ),
      );

      if (anterior.status == TransactionStatus.pagado) {
        await _accounts.applyDelta(
          anterior.accountId,
          -_delta(anterior.type, anterior.amount),
        );
        await _accounts.applyDelta(accountId, _delta(type, amountCentavos));
      }
    });
  }

  /// Borrado suave: si la transacción estaba `pagada`, revierte su efecto
  /// en el saldo antes de marcarla borrada.
  Future<void> eliminar(String id) {
    return _db.transaction(() async {
      final transaccion = await (_db.select(
        _db.transactions,
      )..where((t) => t.id.equals(id))).getSingle();

      final ahora = DateTime.now();
      await (_db.update(_db.transactions)..where((t) => t.id.equals(id)))
          .write(
        TransactionsCompanion(deletedAt: Value(ahora), updatedAt: Value(ahora)),
      );

      if (transaccion.status == TransactionStatus.pagado) {
        await _accounts.applyDelta(
          transaccion.accountId,
          -_delta(transaccion.type, transaccion.amount),
        );
      }
    });
  }

  /// Gastos **pagados** en `[desde, hasta)` (hasta exclusivo) por
  /// `payment_date`, más recientes primero. Base de las consultas de
  /// resumen por período del dashboard de egresos.
  Future<List<Transaction>> gastosEnRango({
    required DateTime desde,
    required DateTime hasta,
  }) {
    return (_db.select(_db.transactions)
          ..where(
            (t) =>
                t.type.equalsValue(TransactionType.gasto) &
                t.status.equalsValue(TransactionStatus.pagado) &
                t.deletedAt.isNull() &
                t.paymentDate.isBiggerOrEqualValue(desde) &
                t.paymentDate.isSmallerThanValue(hasta),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.paymentDate)]))
        .get();
  }

  /// Total de gastos pagados en `[desde, hasta)`.
  Future<int> totalGastoEnRango({
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final total = _db.transactions.amount.sum();
    final query = _db.selectOnly(_db.transactions)
      ..addColumns([total])
      ..where(
        _db.transactions.type.equalsValue(TransactionType.gasto) &
            _db.transactions.status.equalsValue(TransactionStatus.pagado) &
            _db.transactions.deletedAt.isNull() &
            _db.transactions.paymentDate.isBiggerOrEqualValue(desde) &
            _db.transactions.paymentDate.isSmallerThanValue(hasta),
      );
    final fila = await query.getSingle();
    return fila.read(total) ?? 0;
  }

  /// Total de gastos pagados por día dentro de [mes] (índice 0 = día 1).
  /// Alimenta la vista mensual del gráfico de línea del dashboard de
  /// egresos.
  Future<List<int>> gastoPorDiaDelMes(DateTime mes) async {
    final inicio = DateTime(mes.year, mes.month);
    final finExclusivo = DateTime(mes.year, mes.month + 1);
    final dias = finExclusivo.difference(inicio).inDays;
    final totales = List<int>.filled(dias, 0);

    final filas = await gastosEnRango(desde: inicio, hasta: finExclusivo);
    for (final t in filas) {
      totales[t.paymentDate!.day - 1] += t.amount;
    }
    return totales;
  }

  /// Total de gastos pagados por mes dentro de [year] (índice 0 = enero).
  /// Alimenta la vista anual del gráfico de línea del dashboard de egresos.
  Future<List<int>> gastoPorMesDelAnio(int year) async {
    final inicio = DateTime(year);
    final finExclusivo = DateTime(year + 1);
    final totales = List<int>.filled(12, 0);

    final filas = await gastosEnRango(desde: inicio, hasta: finExclusivo);
    for (final t in filas) {
      totales[t.paymentDate!.month - 1] += t.amount;
    }
    return totales;
  }
}
