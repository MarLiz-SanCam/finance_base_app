import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../db/enums.dart';
import 'local_identity_repository.dart';
import 'repository_exceptions.dart';

class AccountsRepository {
  AccountsRepository(this._db, this._identity);

  final AppDatabase _db;
  final LocalIdentityRepository _identity;

  Stream<List<Account>> watchAll() {
    return (_db.select(_db.accounts)
          ..where((a) => a.deletedAt.isNull())
          ..orderBy([(a) => OrderingTerm.asc(a.name)]))
        .watch();
  }

  Future<Account> obtener(String id) {
    return (_db.select(
      _db.accounts,
    )..where((a) => a.id.equals(id) & a.deletedAt.isNull())).getSingle();
  }

  Future<String> crear({
    required String name,
    required AccountType type,
    int saldoInicialCentavos = 0,
  }) async {
    final id = const Uuid().v7();
    final userId = await _identity.obtenerUserId();
    final ahora = DateTime.now();
    await _db.into(_db.accounts).insert(
      AccountsCompanion.insert(
        id: id,
        userId: userId,
        name: name,
        type: type,
        currentBalance: Value(saldoInicialCentavos),
        createdAt: Value(ahora),
        updatedAt: Value(ahora),
      ),
    );
    return id;
  }

  /// Renombra o cambia el tipo de una cuenta. No toca `current_balance`:
  /// el saldo se deriva de las transacciones pagadas (ver [applyDelta] y
  /// [recalcularSaldo]).
  Future<void> actualizar({
    required String id,
    required String name,
    required AccountType type,
  }) {
    return (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(
        name: Value(name),
        type: Value(type),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Borrado suave: marca `deleted_at` en vez de eliminar la fila, para que
  /// la eliminación se pueda propagar a otros dispositivos al sincronizar.
  /// Rechaza el borrado si la cuenta todavía tiene transacciones u
  /// obligaciones activas (no vacías/no borradas) asociadas.
  Future<void> eliminar(String id) async {
    final enUso = await _tieneReferenciasActivas(id);
    if (enUso) {
      throw RegistroEnUsoException(
        'No se puede eliminar la cuenta porque tiene transacciones u '
        'obligaciones asociadas.',
      );
    }
    await (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<bool> _tieneReferenciasActivas(String accountId) async {
    final transaccion =
        await (_db.select(_db.transactions)
              ..where(
                (t) =>
                    (t.accountId.equals(accountId) |
                        t.destinationAccountId.equals(accountId)) &
                    t.deletedAt.isNull(),
              )
              ..limit(1))
            .getSingleOrNull();
    if (transaccion != null) return true;

    final obligacion =
        await (_db.select(_db.obligations)
              ..where(
                (o) => o.accountId.equals(accountId) & o.deletedAt.isNull(),
              )
              ..limit(1))
            .getSingleOrNull();
    return obligacion != null;
  }

  /// Ajusta el saldo de una cuenta sumando [deltaCentavos] (puede ser
  /// negativo) de forma atómica a nivel de SQL. Uso interno: solo debe
  /// invocarse dentro de la misma transacción de BD que confirma el
  /// movimiento que originó el ajuste (ver `TransactionsRepository`), y
  /// solo para transacciones con `status = pagado`.
  Future<void> applyDelta(String accountId, int deltaCentavos) async {
    if (deltaCentavos == 0) return;
    final filasActualizadas =
        await (_db.update(_db.accounts)..where((a) => a.id.equals(accountId)))
            .write(
      AccountsCompanion.custom(
        currentBalance:
            _db.accounts.currentBalance + Variable<int>(deltaCentavos),
        updatedAt: Variable<DateTime>(DateTime.now()),
      ),
    );
    if (filasActualizadas == 0) {
      throw StateError('La cuenta $accountId no existe.');
    }
  }

  /// Recalcula `current_balance` desde cero sumando las transacciones
  /// pagadas de la cuenta. Es una herramienta de integridad/reparación; el
  /// flujo normal usa [applyDelta] para no recorrer toda la tabla en cada
  /// movimiento.
  Future<void> recalcularSaldo(String accountId) async {
    final fila = await _db
        .customSelect(
          'SELECT COALESCE(SUM(CASE WHEN type = ? THEN amount ELSE -amount END), 0) '
          'AS saldo FROM transactions '
          'WHERE account_id = ? AND status = ? AND deleted_at IS NULL',
          variables: [
            Variable<String>(TransactionType.ingreso.name),
            Variable<String>(accountId),
            Variable<String>(TransactionStatus.pagado.name),
          ],
          readsFrom: {_db.transactions},
        )
        .getSingle();
    final saldo = fila.read<int>('saldo');

    await (_db.update(_db.accounts)..where((a) => a.id.equals(accountId)))
        .write(
      AccountsCompanion(
        currentBalance: Value(saldo),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
