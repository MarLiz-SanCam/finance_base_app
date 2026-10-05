import 'package:flutter/material.dart';

import '../../core/config/theme.dart';
import '../db/app_database.dart';

/// Recuerda la paleta y el modo (claro/oscuro/sistema) elegidos, en
/// `local_settings` (clave-valor, no se sincroniza).
class ThemeSettingsRepository {
  ThemeSettingsRepository(this._db);

  final AppDatabase _db;

  static const _clavePaleta = 'theme_palette';
  static const _claveModo = 'theme_mode';

  Future<String?> _leer(String clave) async {
    final fila = await (_db.select(
      _db.localSettings,
    )..where((s) => s.key.equals(clave))).getSingleOrNull();
    return fila?.value;
  }

  Future<void> _guardar(String clave, String valor) {
    return _db
        .into(_db.localSettings)
        .insertOnConflictUpdate(
          LocalSettingsCompanion.insert(key: clave, value: valor),
        );
  }

  Future<AppPalette?> leerPaleta() async {
    final v = await _leer(_clavePaleta);
    for (final p in AppPalette.values) {
      if (p.name == v) return p;
    }
    return null;
  }

  Future<ThemeMode?> leerModo() async {
    final v = await _leer(_claveModo);
    for (final m in ThemeMode.values) {
      if (m.name == v) return m;
    }
    return null;
  }

  Future<void> guardarPaleta(AppPalette paleta) =>
      _guardar(_clavePaleta, paleta.name);

  Future<void> guardarModo(ThemeMode modo) => _guardar(_claveModo, modo.name);
}
