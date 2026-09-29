import 'package:flutter/material.dart';

enum AppThemeMode { light, dark, pink }

class AppTheme {
  /// Archivo plantilla para el diseño de colores y estilos
  /// Creado por: MarLiz-Dev
  /// Fecha: 2024-06-15

  //? Main Palette
  static const Color blueDark = Color(0xFF001A23);
  static const Color pineTeal = Color(0xFF31493C);
  static const Color mutedTeal = Color(0xFF7A9E7E);
  static const Color celadon = Color(0xFFB3EFB2);
  static const Color aliceBlue = Color(0xFFE8F1F2);

  //? TIPOS DE TEXTO PARA LA APLICACIÓN
  static const TextStyle h1 = TextStyle(
    fontFamily: 'plus Jakarta Sans',
    fontSize: 32,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: 'plus Jakarta Sans',
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: 'plus Jakarta Sans',
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontFamily: 'plus Jakarta Sans',
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'plus Jakarta Sans',
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'plus Jakarta Sans',
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle label = TextStyle(
    fontFamily: 'plus Jakarta Sans',
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'plus Jakarta Sans',
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: 'plus Jakarta Sans',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.2,
  );

  static ThemeData _build(Brightness brightness, AppColors c) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      secondary: c.accent,
      onSecondary: c.onPrimary,
      error: Colors
          .red, //TODO: definir nueva paleta de colores para sistema y alertas
      onError: Colors.white,
      surface: c.surface,
      onSurface: c.textPrimary,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Plus Jakarta Sans',
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      textTheme: textThemeFor(c.textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.textPrimary,
        titleTextStyle: h2.copyWith(color: c.textPrimary),
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          disabledBackgroundColor: c.primary.withValues(alpha: 0.5),
          minimumSize: const Size(double.infinity, 60),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          textStyle: buttonTextStyle,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle: TextStyle(
          color: c.textSecondary,
          fontWeight: FontWeight.normal,
        ),
        labelStyle: TextStyle(color: c.textSecondary),
        hintFadeDuration: const Duration(milliseconds: 100),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(c.surface),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        checkColor: WidgetStateProperty.all(c.onPrimary),
        fillColor: WidgetStateProperty.all(c.primary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.surface,
        elevation: 0,
        selectedItemColor: c.primary,
        unselectedItemColor: c.textSecondary,
        selectedLabelStyle: label.copyWith(color: c.primary),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: c.primary,
        textStyle: caption.copyWith(color: c.onPrimary),
      ),
      dividerTheme: DividerThemeData(color: c.divider),
      extensions: [c],
    );
  }

  static ThemeData themeFor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return _build(Brightness.light, _lightColors);
      case AppThemeMode.dark:
        return _build(Brightness.dark, _darkColors);
      case AppThemeMode.pink:
        return _build(Brightness.dark, _pinkColors);
    }
  }

  static const _lightColors = AppColors(
    background: aliceBlue,
    surface: Colors.white,
    primary: mutedTeal,
    onPrimary: pineTeal,
    accent: pineTeal,
    textPrimary: blueDark,
    textSecondary: pineTeal,
    divider: mutedTeal,
    chatBubbleOutgoing: mutedTeal,
    onChatBubbleOutgoing: aliceBlue,
    chatBubbleIncoming: celadon,
    onChatBubbleIncoming: blueDark,
  );

  static const _darkColors = AppColors(
    background: blueDark,
    surface: blueDark,
    primary: pineTeal,
    onPrimary: aliceBlue,
    accent: mutedTeal,
    textPrimary: aliceBlue,
    textSecondary: celadon,
    divider: mutedTeal,
    chatBubbleOutgoing: pineTeal,
    onChatBubbleOutgoing: aliceBlue,
    chatBubbleIncoming: celadon,
    onChatBubbleIncoming: blueDark,
  );

  static const _pinkColors = AppColors(
    background: blueDark,
    surface: blueDark,
    primary: celadon,
    onPrimary: Colors.white,
    accent: celadon,
    textPrimary: Colors.white,
    textSecondary: celadon,
    divider: celadon,
    chatBubbleOutgoing: celadon,
    onChatBubbleOutgoing: Colors.white,
    chatBubbleIncoming: celadon,
    onChatBubbleIncoming: celadon,
  );

  /// Arma el [TextTheme] a partir de los estilos de arriba (h1/h2/h3/body/
  /// etc.), coloreados con [color]. Público para poder reutilizar la
  /// tipografía del tema incluso cuando no se usa [themeFor] completo (ej.
  /// mientras la paleta de [AppColors] no está definitiva todavía).
  static TextTheme textThemeFor(Color color) => TextTheme(
    displayLarge: h1.copyWith(color: color),
    displayMedium: h2.copyWith(color: color),
    displaySmall: h3.copyWith(color: color),
    headlineLarge: h1.copyWith(color: color),
    headlineMedium: h2.copyWith(color: color),
    headlineSmall: h3.copyWith(color: color),
    titleLarge: buttonTextStyle.copyWith(color: color),
    titleMedium: body.copyWith(color: color),
    titleSmall: bodySmall.copyWith(color: color),
    bodyLarge: body.copyWith(color: color),
    bodyMedium: bodySmall.copyWith(color: color),
    labelSmall: caption.copyWith(color: color),
  );
}

class AppColors extends ThemeExtension<AppColors> {
  final Color background; //?Para los scaffold
  final Color surface; //? tarjetas, Appbars, BottomNavbars
  final Color primary; //? botón principal, acentos fuertes
  final Color onPrimary; //? textos/ iconos sobre el primary
  final Color accent; //? acentos secundarios y realces
  final Color textPrimary; //? titulos y cuerpos
  final Color textSecondary; //? textos atenuados, hints
  final Color divider; //? divisores, lineas y bordes suaves
  final Color chatBubbleOutgoing; //? fondo de burbuja de mensajes propios
  final Color onChatBubbleOutgoing; //? texto sobre chatBubbleOutgoing
  final Color chatBubbleIncoming; //? fondo de burbuja de mensajes recibidos
  final Color onChatBubbleIncoming; //? texto sobre chatBubbleIncoming

  const AppColors({
    required this.background,
    required this.surface,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.chatBubbleOutgoing,
    required this.onChatBubbleOutgoing,
    required this.chatBubbleIncoming,
    required this.onChatBubbleIncoming,
  });
  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? primary,
    Color? onPrimary,
    Color? accent,
    Color? textPrimary,
    Color? textSecondary,
    Color? divider,
    Color? chatBubbleOutgoing,
    Color? onChatBubbleOutgoing,
    Color? chatBubbleIncoming,
    Color? onChatBubbleIncoming,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      accent: accent ?? this.accent,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      divider: divider ?? this.divider,
      chatBubbleOutgoing: chatBubbleOutgoing ?? this.chatBubbleOutgoing,
      onChatBubbleOutgoing: onChatBubbleOutgoing ?? this.onChatBubbleOutgoing,
      chatBubbleIncoming: chatBubbleIncoming ?? this.chatBubbleIncoming,
      onChatBubbleIncoming: onChatBubbleIncoming ?? this.onChatBubbleIncoming,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      chatBubbleOutgoing: Color.lerp(
        chatBubbleOutgoing,
        other.chatBubbleOutgoing,
        t,
      )!,
      onChatBubbleOutgoing: Color.lerp(
        onChatBubbleOutgoing,
        other.onChatBubbleOutgoing,
        t,
      )!,
      chatBubbleIncoming: Color.lerp(
        chatBubbleIncoming,
        other.chatBubbleIncoming,
        t,
      )!,
      onChatBubbleIncoming: Color.lerp(
        onChatBubbleIncoming,
        other.onChatBubbleIncoming,
        t,
      )!,
    );
  }
}

/// ~MarLIz was here~
