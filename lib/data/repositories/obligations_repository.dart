import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/obligation_schedule.dart';
import '../db/app_database.dart';
import '../db/enums.dart';
import 'local_identity_repository.dart';

class ObligationsRepository {
  ObligationsRepository(this._db, this._identity);

  final AppDatabase _db;
  final LocalIdentityRepository _identity;

  Stream<List<Obligation>> watchAll() {
    return (_db.select(
      _db.obligations,
    )..where((o) => o.deletedAt.isNull())).watch();
  }

  Stream<List<Obligation>> watchActivas() {
    return (_db.select(_db.obligations)
          ..where(
            (o) =>
                o.status.equalsValue(ObligationStatus.activo) &
                o.deletedAt.isNull(),
          )
          ..orderBy([(o) => OrderingTerm.asc(o.concept)]))
        .watch();
  }

  Future<Obligation> obtener(String id) {
    return (_db.select(
      _db.obligations,
    )..where((o) => o.id.equals(id) & o.deletedAt.isNull())).getSingle();
  }

  Future<String> crear({
    required String concept,
    required String categoryId,
    String? accountId,
    required ObligationType type,
    required ObligationFrequency frequency,
    int? amountPerPeriodCentavos,
    int? paymentDay,
    int? paymentDay2,
    int? totalAmountCentavos,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (type == ObligationType.progresivo &&
        (totalAmountCentavos == null || startDate == null)) {
      throw ArgumentError(
        'Una obligación progresiva requiere totalAmountCentavos y startDate.',
      );
    }
    final id = const Uuid().v7();
    final userId = await _identity.obtenerUserId();
    final ahora = DateTime.now();
    await _db.into(_db.obligations).insert(
      ObligationsCompanion.insert(
        id: id,
        userId: userId,
        concept: concept,
        categoryId: categoryId,
        accountId: Value(accountId),
        type: type,
        frequency: frequency,
        amountPerPeriod: Value(amountPerPeriodCentavos),
        paymentDay: Value(paymentDay),
        paymentDay2: Value(paymentDay2),
        totalAmount: Value(totalAmountCentavos),
        startDate: Value(startDate),
        endDate: Value(endDate),
        createdAt: Value(ahora),
        updatedAt: Value(ahora),
      ),
    );
    return id;
  }

  Future<void> cambiarEstado(String id, ObligationStatus status) {
    return (_db.update(_db.obligations)..where((o) => o.id.equals(id))).write(
      ObligationsCompanion(status: Value(status), updatedAt: Value(DateTime.now())),
    );
  }

  /// Edita una obligación existente. `type` no se puede cambiar aquí a
  /// propósito: determina si aplican los campos de progresivo y qué tipo de
  /// categoría corresponde, así que cambiarlo a mitad de vida es
  /// conceptualmente otra obligación (se borra y se crea una nueva).
  Future<void> actualizar({
    required String id,
    required String concept,
    required String categoryId,
    String? accountId,
    required ObligationFrequency frequency,
    int? amountPerPeriodCentavos,
    int? paymentDay,
    int? paymentDay2,
    int? totalAmountCentavos,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final actual = await obtener(id);
    if (actual.type == ObligationType.progresivo &&
        (totalAmountCentavos == null || startDate == null)) {
      throw ArgumentError(
        'Una obligación progresiva requiere totalAmountCentavos y startDate.',
      );
    }
    await (_db.update(_db.obligations)..where((o) => o.id.equals(id))).write(
      ObligationsCompanion(
        concept: Value(concept),
        categoryId: Value(categoryId),
        accountId: Value(accountId),
        frequency: Value(frequency),
        amountPerPeriod: Value(amountPerPeriodCentavos),
        paymentDay: Value(paymentDay),
        paymentDay2: Value(paymentDay2),
        totalAmount: Value(totalAmountCentavos),
        startDate: Value(startDate),
        endDate: Value(endDate),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Borrado suave (ver `AccountsRepository.eliminar`). Cancela (no borra)
  /// las transacciones `pendiente` que todavía dependían de esta
  /// obligación, para no dejar cuentas por pagar huérfanas que nadie va a
  /// confirmar nunca; el historial ya `pagado` se conserva intacto.
  Future<void> eliminar(String id) {
    return _db.transaction(() async {
      final ahora = DateTime.now();
      await (_db.update(_db.transactions)..where(
            (t) =>
                t.obligationId.equals(id) &
                t.status.equalsValue(TransactionStatus.pendiente),
          ))
          .write(
            TransactionsCompanion(
              status: Value(TransactionStatus.cancelado),
              updatedAt: Value(ahora),
            ),
          );
      await (_db.update(_db.obligations)..where((o) => o.id.equals(id)))
          .write(
            ObligationsCompanion(
              deletedAt: Value(ahora),
              updatedAt: Value(ahora),
            ),
          );
    });
  }

  /// Saldo restante de una obligación progresiva: total menos lo ya
  /// `pagado` (un pago todavía `pendiente` de confirmar no reduce la
  /// deuda). `null` si la obligación no es progresiva.
  Future<int?> saldoRestante(String obligationId) async {
    final obligation = await obtener(obligationId);
    if (obligation.type != ObligationType.progresivo) return null;

    final total = _db.transactions.amount.sum();
    final query = _db.selectOnly(_db.transactions)
      ..addColumns([total])
      ..where(
        _db.transactions.obligationId.equals(obligationId) &
            _db.transactions.status.equalsValue(TransactionStatus.pagado),
      );
    final pagado = await query.map((r) => r.read(total) ?? 0).getSingle();

    return (obligation.totalAmount ?? 0) - pagado;
  }

  /// Marca finalizada una obligación progresiva si ya no tiene saldo
  /// restante. Se invoca después de confirmar un pago (ver
  /// `TransactionsRepository.confirmarPago`).
  Future<void> finalizarSiCorresponde(String obligationId) async {
    final restante = await saldoRestante(obligationId);
    if (restante != null && restante <= 0) {
      await cambiarEstado(obligationId, ObligationStatus.finalizado);
    }
  }

  /// El motor de automatización: para cada obligación activa, genera
  /// transacciones `pendiente` (due_date = ocurrencia programada, sin
  /// payment_date, sin afectar el saldo) para las ocurrencias entre su
  /// marca de agua (`last_generated_date`, o `start_date`/fecha de creación
  /// si nunca se generó) y [horizonte] — por defecto hoy + 30 días, para que
  /// "próximos a vencer" pueda anticipar cobros futuros y no solo mostrar
  /// atrasados. Avanza `last_generated_date` aunque no haya ocurrencias
  /// nuevas en la ventana, para no reescanearla la próxima vez.
  ///
  /// Una obligación sin `account_id` asignado se omite por completo (sin
  /// cuenta no hay dónde afectar el saldo al confirmar el pago) y su marca
  /// de agua no avanza, así que en cuanto se le asigne una cuenta el motor
  /// generará retroactivamente todo lo que falte.
  ///
  /// Debe llamarse al iniciar la app: no hay tareas en background reales en
  /// una app local, así que esto sustituye a un cron de servidor.
  Future<void> generarPagosPendientes({DateTime? horizonte}) async {
    final limite = horizonte ?? DateTime.now().add(const Duration(days: 30));
    final activas = await (_db.select(_db.obligations)..where(
          (o) =>
              o.status.equalsValue(ObligationStatus.activo) &
              o.deletedAt.isNull(),
        ))
        .get();

    for (final obligation in activas) {
      if (obligation.accountId == null) continue;
      await _generarPendientesDeUnaObligacion(obligation, limite);
    }
  }

  Future<void> _generarPendientesDeUnaObligacion(
    Obligation obligation,
    DateTime limite,
  ) async {
    final marcaDeAgua = obligation.lastGeneratedDate;
    final desde = marcaDeAgua != null
        ? marcaDeAgua.add(const Duration(days: 1))
        : (obligation.startDate ?? obligation.createdAt);
    if (!limite.isAfter(desde)) return;

    final ocurrencias = ObligationSchedule.ocurrenciasEnRango(
      frequency: obligation.frequency,
      paymentDay: obligation.paymentDay,
      paymentDay2: obligation.paymentDay2,
      desde: desde,
      hasta: limite,
      anclaAnual: obligation.startDate,
    );

    final userId = await _identity.obtenerUserId();
    final ahora = DateTime.now();
    final tipoTransaccion = obligation.type == ObligationType.ingresoFijo
        ? TransactionType.ingreso
        : TransactionType.gasto;

    await _db.transaction(() async {
      for (final fecha in ocurrencias) {
        await _db.into(_db.transactions).insert(
          TransactionsCompanion.insert(
            id: const Uuid().v7(),
            userId: userId,
            concept: obligation.concept,
            // 0 = "todavía no se sabe cuánto es" (obligación sin monto
            // fijo, ej. la luz). Nunca ocurre en una transacción real, así
            // que `confirmarPago` lo detecta y exige el monto verdadero.
            amount: obligation.amountPerPeriod ?? 0,
            dueDate: fecha,
            type: tipoTransaccion,
            status: const Value(TransactionStatus.pendiente),
            accountId: obligation.accountId!,
            categoryId: Value(obligation.categoryId),
            obligationId: Value(obligation.id),
            createdAt: Value(ahora),
            updatedAt: Value(ahora),
          ),
        );
      }
      await (_db.update(_db.obligations)..where((o) => o.id.equals(obligation.id)))
          .write(
        ObligationsCompanion(
          lastGeneratedDate: Value(limite),
          updatedAt: Value(ahora),
        ),
      );
    });
  }
}
