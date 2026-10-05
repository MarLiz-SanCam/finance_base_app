import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/theme.dart';
import '../data/repositories/theme_settings_repository.dart';
import 'database_provider.dart';

final themeSettingsRepositoryProvider = Provider<ThemeSettingsRepository>((
  ref,
) {
  return ThemeSettingsRepository(ref.watch(appDatabaseProvider));
});

class ThemeSettings {
  const ThemeSettings({required this.palette, required this.mode});

  final AppPalette palette;
  final ThemeMode mode;

  ThemeSettings copyWith({AppPalette? palette, ThemeMode? mode}) =>
      ThemeSettings(palette: palette ?? this.palette, mode: mode ?? this.mode);
}

/// Paleta y modo activos. Llamar [load] una vez antes de `runApp` para que
/// la primera pantalla ya use el tema guardado (sin parpadeo).
class ThemeController extends Notifier<ThemeSettings> {
  @override
  ThemeSettings build() =>
      const ThemeSettings(palette: AppPalette.green, mode: ThemeMode.system);

  Future<void> load() async {
    final repo = ref.read(themeSettingsRepositoryProvider);
    state = ThemeSettings(
      palette: await repo.leerPaleta() ?? state.palette,
      mode: await repo.leerModo() ?? state.mode,
    );
  }

  Future<void> setPalette(AppPalette palette) async {
    state = state.copyWith(palette: palette);
    await ref.read(themeSettingsRepositoryProvider).guardarPaleta(palette);
  }

  Future<void> setMode(ThemeMode mode) async {
    state = state.copyWith(mode: mode);
    await ref.read(themeSettingsRepositoryProvider).guardarModo(mode);
  }
}

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeSettings>(ThemeController.new);
