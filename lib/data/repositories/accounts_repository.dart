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
    int? limiteCreditoCentavos,
    int? diaCorte,
    int? diaPago,
  }) async {
    final limite = _limiteValido(type, limiteCreditoCentavos);
    final corte = _diaValido(type, diaCorte, 'de corte');
    final pago = _diaValido(type, diaPago, 'de pago');
    final id = const Uuid().v7();
    final userId = await _identity.obtenerUserId();
    final ahora = DateTime.now();
    await _db
        .into(_db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: id,
            userId: userId,
            name: name,
            type: type,
            currentBalance: Value(saldoInicialCentavos),
            creditLimit: Value(limite),
            statementDay: Value(corte),
            paymentDueDay: Value(pago),
            createdAt: Value(ahora),
            updatedAt: Value(ahora),
          ),
        );
    return id;
  }

  /// Las cuentas de crédito exigen un límite mayor a cero; en el resto de
  /// tipos el límite se descarta (`null`).
  int? _limiteValido(AccountType type, int? limiteCentavos) {
    if (type != AccountType.credito) return null;
    if (limiteCentavos == null || limiteCentavos <= 0) {
      throw ArgumentError(
        'Una cuenta de crédito necesita un límite de crédito mayor a cero.',
      );
    }
    return limiteCentavos;
  }

  /// Día del mes (1-31) de corte o de pago; solo se conserva en cuentas de
  /// crédito y es opcional (`null` en cuentas anteriores a esta función).
  int? _diaValido(AccountType type, int? dia, String etiqueta) {
    if (type != AccountType.credito || dia == null) return null;
    if (dia < 1 || dia > 31) {
      throw ArgumentError('El día $etiqueta debe estar entre 1 y 31.');
    }
    return dia;
  }

  /// Renombra o cambia el tipo, límite y fechas de corte/pago de una cuenta.
  /// No toca `current_balance`: el saldo se deriva de las transacciones
  /// pagadas (ver [applyDelta] y [recalcularSaldo]).
  Future<void> actualizar({
    required String id,
    required String name,
    required AccountType type,
    int? limiteCreditoCentavos,
    int? diaCorte,
    int? diaPago,
  }) {
    final limite = _limiteValido(type, limiteCreditoCentavos);
    final corte = _diaValido(type, diaCorte, 'de corte');
    final pago = _diaValido(type, diaPago, 'de pago');
    return (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(
        name: Value(name),
        type: Value(type),
        creditLimit: Value(limite),
        statementDay: Value(corte),
        paymentDueDay: Value(pago),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Verifica que restar [montoCentavos] de la cuenta no exceda su límite de
  /// crédito. Solo aplica a cuentas de crédito con límite; en las demás no
  /// hace nada. Debe llamarse antes de registrar un cargo (gasto o
  /// transferencia de salida) sobre la cuenta.
  Future<void> validarCapacidad(String accountId, int montoCentavos) async {
    final cuenta = await obtener(accountId);
    final limite = cuenta.creditLimit;
    if (cuenta.type != AccountType.credito || limite == null) return;
    final disponible = limite + cuenta.currentBalance;
    if (montoCentavos > disponible) {
      throw CreditoInsuficienteException(
        'El cargo excede el crédito disponible de "${cuenta.name}".',
        disponibleCentavos: disponible < 0 ? 0 : disponible,
      );
    }
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
        await (_db.update(
          _db.accounts,
        )..where((a) => a.id.equals(accountId))).write(
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

    await (_db.update(
      _db.accounts,
    )..where((a) => a.id.equals(accountId))).write(
      AccountsCompanion(
        currentBalance: Value(saldo),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
