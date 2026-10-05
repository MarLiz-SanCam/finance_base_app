import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../db/enums.dart';
import 'local_identity_repository.dart';
import 'repository_exceptions.dart';

class CategoriesRepository {
  CategoriesRepository(this._db, this._identity);

  final AppDatabase _db;
  final LocalIdentityRepository _identity;

  Stream<List<Category>> watchAll() {
    return (_db.select(_db.categories)
          ..where((c) => c.deletedAt.isNull())
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch();
  }

  Stream<List<Category>> watchByType(CategoryType type) {
    return (_db.select(
      _db.categories,
    )..where((c) => c.type.equalsValue(type) & c.deletedAt.isNull())).watch();
  }

  Future<Category> obtener(String id) {
    return (_db.select(
      _db.categories,
    )..where((c) => c.id.equals(id) & c.deletedAt.isNull())).getSingle();
  }

  /// [color] es el ARGB (`Color.toARGB32()`) elegido en
  /// [AppColorPicker]/`FormCategoriaSheet`; el valor por defecto solo cubre
  /// llamadas que no pasan por ese formulario (ej. pruebas), igual que el
  /// default de la columna en `categories_table.dart`.
  Future<String> crear({
    required String name,
    required CategoryType type,
    int color = 0xFF2A78D6,
    int presupuestoQuincenalCentavos = 0,
  }) async {
    final id = const Uuid().v7();
    final userId = await _identity.obtenerUserId();
    final ahora = DateTime.now();
    await _db
        .into(_db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: id,
            userId: userId,
            name: name,
            type: type,
            color: Value(color),
            budgetLimit: Value(presupuestoQuincenalCentavos),
            createdAt: Value(ahora),
            updatedAt: Value(ahora),
          ),
        );
    return id;
  }

  Future<void> actualizar({
    required String id,
    required String name,
    required int color,
    required int presupuestoQuincenalCentavos,
  }) {
    return (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
        name: Value(name),
        color: Value(color),
        budgetLimit: Value(presupuestoQuincenalCentavos),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Borrado suave (ver `AccountsRepository.eliminar`). Rechaza el borrado
  /// si la categoría todavía tiene transacciones u obligaciones activas.
  Future<void> eliminar(String id) async {
    final enUso = await _tieneReferenciasActivas(id);
    if (enUso) {
      throw RegistroEnUsoException(
        'No se puede eliminar la categoría porque tiene transacciones u '
        'obligaciones asociadas.',
      );
    }
    await (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<bool> _tieneReferenciasActivas(String categoryId) async {
    final transaccion =
        await (_db.select(_db.transactions)
              ..where(
                (t) => t.categoryId.equals(categoryId) & t.deletedAt.isNull(),
              )
              ..limit(1))
            .getSingleOrNull();
    if (transaccion != null) return true;

    final obligacion =
        await (_db.select(_db.obligations)
              ..where(
                (o) => o.categoryId.equals(categoryId) & o.deletedAt.isNull(),
              )
              ..limit(1))
            .getSingleOrNull();
    return obligacion != null;
  }

  /// Total pagado (status=pagado) de [type] en la categoría dentro de
  /// `[desde, hasta)`, usando `payment_date` (cuándo se pagó de verdad, no
  /// cuándo vencía). Un movimiento todavía `pendiente` no cuenta aquí.
  Future<int> _montoEnRango(
    String categoryId,
    TransactionType type, {
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final total = _db.transactions.amount.sum();
    final query = _db.selectOnly(_db.transactions)
      ..addColumns([total])
      ..where(
        _db.transactions.categoryId.equals(categoryId) &
            _db.transactions.type.equalsValue(type) &
            _db.transactions.status.equalsValue(TransactionStatus.pagado) &
            _db.transactions.deletedAt.isNull() &
            _db.transactions.paymentDate.isBiggerOrEqualValue(desde) &
            _db.transactions.paymentDate.isSmallerThanValue(hasta),
      );

    final fila = await query.getSingle();
    return fila.read(total) ?? 0;
  }

  /// Gastado en la categoría dentro de `[desde, hasta)`. Se compara contra
  /// `budget_limit` (presupuesto por quincena) para mostrar el avance del
  /// presupuesto de la quincena vigente.
  Future<int> gastadoEnRango(
    String categoryId, {
    required DateTime desde,
    required DateTime hasta,
  }) => _montoEnRango(
    categoryId,
    TransactionType.gasto,
    desde: desde,
    hasta: hasta,
  );

  /// Ingresado en la categoría dentro de `[desde, hasta)`. Simétrico a
  /// [gastadoEnRango]; las categorías de ingreso no tienen `budget_limit`,
  /// así que aquí solo se informa el monto, sin comparación.
  Future<int> ingresadoEnRango(
    String categoryId, {
    required DateTime desde,
    required DateTime hasta,
  }) => _montoEnRango(
    categoryId,
    TransactionType.ingreso,
    desde: desde,
    hasta: hasta,
  );
}
