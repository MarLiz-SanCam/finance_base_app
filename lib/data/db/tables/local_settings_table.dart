import 'package:drift/drift.dart';

/// Configuración local del dispositivo, clave-valor. No se sincroniza.
///
/// Uso actual: guardar el `device_user_id` (ver `LocalIdentityRepository`) —
/// un UUID generado una vez en este dispositivo que se usa como `user_id`
/// en todas las tablas sincronizables mientras no existe login real. Cuando
/// haya backend, ese UUID se reconcilia con el `id` que asigne el servidor.
class LocalSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
