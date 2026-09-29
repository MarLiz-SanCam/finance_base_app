import '../db/app_database.dart';

/// Recuerda qué showcases ya vio el usuario, en `local_settings`
/// (clave-valor, no se sincroniza). El valor guardado es la versión del
/// showcase que se vio: si la pantalla sube de versión (nuevos pasos), se
/// vuelve a mostrar una vez.
class ShowcaseProgressRepository {
  ShowcaseProgressRepository(this._db);

  final AppDatabase _db;

  static String _clave(String id) => 'showcase_visto_$id';

  Future<bool> fueVisto(String id, int version) async {
    final fila = await (_db.select(
      _db.localSettings,
    )..where((s) => s.key.equals(_clave(id)))).getSingleOrNull();
    return fila != null && (int.tryParse(fila.value) ?? 0) >= version;
  }

  Future<void> marcarVisto(String id, int version) {
    return _db
        .into(_db.localSettings)
        .insertOnConflictUpdate(
          LocalSettingsCompanion.insert(
            key: _clave(id),
            value: version.toString(),
          ),
        );
  }
}
