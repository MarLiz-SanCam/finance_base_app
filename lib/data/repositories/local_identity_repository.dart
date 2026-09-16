import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';

/// Resuelve el `user_id` que se estampa en cada registro mientras no existe
/// backend/login real: un UUID generado una vez en este dispositivo y
/// guardado en `local_settings`. Cuando haya autenticación real, este ID se
/// reconcilia con el que asigne el servidor (ese paso no está construido
/// todavía, solo el mecanismo local).
class LocalIdentityRepository {
  LocalIdentityRepository(this._db);

  static const _clave = 'device_user_id';

  final AppDatabase _db;
  String? _cache;

  Future<String> obtenerUserId() async {
    final cacheado = _cache;
    if (cacheado != null) return cacheado;

    final fila = await (_db.select(
      _db.localSettings,
    )..where((s) => s.key.equals(_clave))).getSingleOrNull();
    if (fila != null) {
      _cache = fila.value;
      return fila.value;
    }

    final nuevoId = const Uuid().v7();
    await _db
        .into(_db.localSettings)
        .insert(
          LocalSettingsCompanion.insert(key: _clave, value: nuevoId),
          mode: InsertMode.insertOrIgnore,
        );
    // Si dos llamadas concurrentes entraron aquí a la vez, gana la primera
    // fila que quedó insertada; se relee para no quedarse con un ID propio
    // descartado.
    final filaFinal = await (_db.select(
      _db.localSettings,
    )..where((s) => s.key.equals(_clave))).getSingle();
    _cache = filaFinal.value;
    return filaFinal.value;
  }
}
