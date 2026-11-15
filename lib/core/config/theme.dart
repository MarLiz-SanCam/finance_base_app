import 'package:material_ui/material_ui.dart';

/// Paleta de color elegida; cada una tiene versión clara y oscura.
enum AppPalette { green, yellow, pink, teal }

class AppTheme {
  /// Archivo plantilla para el diseño de colores y estilos
  /// Creado por: MarLiz-Dev
  /// Fecha: 2024-06-15

  //? Green pállette
  static const Color blueDark = Color(0xFF001A23);
  static const Color pineTeal = Color(0xFF31493C);
  static const Color mutedTeal = Color(0xFF7A9E7E);
  static const Color celadon = Color(0xFFB3EFB2);
  static const Color aliceBlue = Color(0xFFE8F1F2);

  //? Pink pállette
  static const Color coffeeBean = Color(0xFF110305);
  static const Color nightBordeaux = Color(0xFF23050b);
  static const Color pinkTeal = Color(0xFFE9788A);
  static const Color pinkyshTeal = Color(0xFFFDC3CC);
  static const Color lavenderBlush = Color(0xFFFBEEF0);

  //? Yellow pállette
  static const Color jetNlack = Color(0xFF0A2833);
  static const Color darkTeal = Color(0xFF145066);
  static const Color mustard = Color(0xFFfee286);
  static const Color jasmine = Color(0xFFfef0c2);
  static const Color porcelain = Color(0xFFfffdf7);

  //? Teal pállette
  static const Color dark = Color(0xFF0A0D10);
  static const Color submarine = Color(0xFF11161C);
  static const Color lightTeal = Color(0xFF509EA5);
  static const Color teal = Color(0xFFACD4D7);
  static const Color lavenderTeal = Color(0xFFE6E8EB);

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

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  static ThemeData _build(Brightness brightness, AppColors c) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      secondary: c.accent,
      onSecondary: c.onPrimary,
      error: Colors.red,
      //TODO: definir nueva paleta de colores para sistema y alertas
      onError: Colors.white,
      surface: c.surface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      primaryContainer: c.subtle,
      onPrimaryContainer: c.textPrimary,
      secondaryContainer: c.subtle,
      onSecondaryContainer: c.textPrimary,
      surfaceContainerHighest: c.subtle,
      outline: c.divider,
      outlineVariant: c.divider,
      inverseSurface: c.textPrimary,
      onInverseSurface: c.background,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Plus Jakarta Sans',
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      textTheme: textThemeFor(c.textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        titleTextStyle: h3.copyWith(color: c.textPrimary),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.divider),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 4),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.subtle,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          disabledBackgroundColor: c.primary.withValues(alpha: 0.5),
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: buttonTextStyle,
        ),
      ),
      // Por defecto el segmento seleccionado usa `secondaryContainer`, que
      // sin definirlo cae en `secondary` (el acento: el tono más oscuro de
      // la paleta clara). Se fija a `primary`, igual que el ítem activo de
      // la barra de navegación y los botones.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.selected) ? c.primary : null,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.selected) ? c.onPrimary : null,
          ),
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
        border: _inputBorder(c.divider),
        enabledBorder: _inputBorder(c.divider),
        focusedBorder: _inputBorder(c.textPrimary, width: 1.5),
        errorBorder: _inputBorder(scheme.error),
        focusedErrorBorder: _inputBorder(scheme.error, width: 1.5),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(c.surface),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  /// Tema completo para [palette] en el [brightness] pedido (6 combinaciones).
  static ThemeData themeFor(AppPalette palette, Brightness brightness) {
    return _build(brightness, colorsFor(palette, brightness));
  }

  static AppColors colorsFor(AppPalette palette, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (palette) {
      case AppPalette.green:
        return isDark ? _greenDark : _greenLight;
      case AppPalette.yellow:
        return isDark ? _yellowDark : _yellowLight;
      case AppPalette.pink:
        return isDark ? _pinkDark : _pinkLight;
      case AppPalette.teal:
        return isDark ? _tealDark : _tealLight;
    }
  }

  //? Cada paleta va de más oscuro (1) a más claro (5).
  //? Light: fondo = 5, primario = 3, texto = 1. Dark: fondo = 1, primario = 3, texto = 5.
  static const _greenLight = AppColors(
    background: Color(0xFFFAFAF9),
    surface: Colors.white,
    primary: mutedTeal,
    onPrimary: blueDark,
    accent: pineTeal,
    textPrimary: blueDark,
    textSecondary: Color(0xFF6B7280),
    divider: Color(0xFFE7E7E4),
    chatBubbleOutgoing: mutedTeal,
    onChatBubbleOutgoing: blueDark,
    chatBubbleIncoming: celadon,
    onChatBubbleIncoming: blueDark,
    subtle: Color(0xFFF1F1EF),
  );

  static const _greenDark = AppColors(
    background: Color(0xFF0E1214),
    surface: Color(0xFF161B1E),
    primary: mutedTeal,
    onPrimary: blueDark,
    accent: celadon,
    textPrimary: aliceBlue,
    textSecondary: Color(0xFF9AA1A9),
    divider: Color(0xFF262C30),
    chatBubbleOutgoing: pineTeal,
    onChatBubbleOutgoing: aliceBlue,
    chatBubbleIncoming: celadon,
    onChatBubbleIncoming: blueDark,
    subtle: Color(0xFF1E2427),
  );

  static const _yellowLight = AppColors(
    background: Color(0xFFFAFAF9),
    surface: Colors.white,
    primary: mustard,
    onPrimary: jetNlack,
    accent: darkTeal,
    textPrimary: jetNlack,
    textSecondary: Color(0xFF6B7280),
    divider: Color(0xFFE7E7E4),
    chatBubbleOutgoing: mustard,
    onChatBubbleOutgoing: jetNlack,
    chatBubbleIncoming: jasmine,
    onChatBubbleIncoming: jetNlack,
    subtle: Color(0xFFF1F1EF),
  );

  static const _yellowDark = AppColors(
    background: Color(0xFF0F1214),
    surface: Color(0xFF161B1E),
    primary: mustard,
    onPrimary: jetNlack,
    accent: jasmine,
    textPrimary: porcelain,
    textSecondary: Color(0xFF9AA1A9),
    divider: Color(0xFF262C30),
    chatBubbleOutgoing: darkTeal,
    onChatBubbleOutgoing: porcelain,
    chatBubbleIncoming: jasmine,
    onChatBubbleIncoming: jetNlack,
    subtle: Color(0xFF1E2427),
  );

  static const _pinkLight = AppColors(
    background: Color(0xFFFAFAF9),
    surface: Colors.white,
    primary: pinkTeal,
    onPrimary: coffeeBean,
    accent: nightBordeaux,
    textPrimary: coffeeBean,
    textSecondary: Color(0xFF6B7280),
    divider: Color(0xFFE7E7E4),
    chatBubbleOutgoing: pinkTeal,
    onChatBubbleOutgoing: coffeeBean,
    chatBubbleIncoming: pinkyshTeal,
    onChatBubbleIncoming: coffeeBean,
    subtle: Color(0xFFF1F1EF),
  );

  static const _tealLight = AppColors(
    background: Color(0xFFFAFAF9),
    surface: Colors.white,
    primary: lightTeal,
    onPrimary: dark,
    accent: submarine,
    textPrimary: dark,
    textSecondary: Color(0xFF6B7280),
    divider: Color(0xFFE7E7E4),
    chatBubbleOutgoing: lightTeal,
    onChatBubbleOutgoing: dark,
    chatBubbleIncoming: teal,
    onChatBubbleIncoming: dark,
    subtle: Color(0xFFF1F1EF),
  );

  static const _tealDark = AppColors(
    background: Color(0xFF0D1012),
    surface: Color(0xFF161B1E),
    primary: lightTeal,
    onPrimary: dark,
    accent: teal,
    textPrimary: lavenderTeal,
    textSecondary: Color(0xFF9AA1A9),
    divider: Color(0xFF262C30),
    chatBubbleOutgoing: submarine,
    onChatBubbleOutgoing: lavenderTeal,
    chatBubbleIncoming: teal,
    onChatBubbleIncoming: dark,
    subtle: Color(0xFF1E2427),
  );

  static const _pinkDark = AppColors(
    background: Color(0xFF121012),
    surface: Color(0xFF161B1E),
    primary: pinkTeal,
    onPrimary: coffeeBean,
    accent: pinkyshTeal,
    textPrimary: lavenderBlush,
    textSecondary: Color(0xFF9AA1A9),
    divider: Color(0xFF262C30),
    chatBubbleOutgoing: nightBordeaux,
    onChatBubbleOutgoing: lavenderBlush,
    chatBubbleIncoming: pinkyshTeal,
    onChatBubbleIncoming: coffeeBean,
    subtle: Color(0xFF1E2427),
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
  final Color subtle; //? relleno tenue (chips, pistas de progreso, tab activo)

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
    required this.subtle,
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
    Color? subtle,
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
      subtle: subtle ?? this.subtle,
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
      subtle: Color.lerp(subtle, other.subtle, t)!,
    );
  }
}

/// ~MarLIz was here~
