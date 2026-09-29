import 'package:flutter/widgets.dart';

/// Pantallas (y tabs internos) que tienen su propio showcase. Cada una se
/// marca como vista por separado (ver `ShowcaseProgressRepository`).
///
/// [version] se sube cuando cambian los pasos de esa pantalla: quien ya vio
/// la versión anterior vuelve a ver el showcase una vez con lo nuevo.
enum ShowcasePantalla {
  resumen(version: 2),
  balanceGastos(version: 2),
  balanceIngresos(version: 2),
  orgCuentas(version: 2),
  orgCategorias(version: 2),
  orgObligaciones(version: 2),
  usuario(version: 1);

  const ShowcasePantalla({required this.version});

  final int version;
  String get id => name;
}

/// Registro único de las [GlobalKey] de cada paso del showcase. Todas las
/// pantallas viven montadas a la vez en el `IndexedStack` de `RootShell`, por
/// eso las claves son globales y cada pantalla arranca solo la lista de
/// [pasosDe] que le corresponde.
abstract final class ShowcaseKeys {
  // Comunes a todas las pantallas (viven en RootShell).
  static final botonCentral = GlobalKey(debugLabel: 'showcase_botonCentral');
  static final barraNavegacion = GlobalKey(debugLabel: 'showcase_barraNav');

  // Resumen.
  static final resumenBalance = GlobalKey(debugLabel: 'showcase_resumenBal');
  static final resumenGrafico = GlobalKey(debugLabel: 'showcase_resumenGraf');
  static final resumenPeriodo = GlobalKey(debugLabel: 'showcase_resumenPer');

  // Balance (la barra de tabs es compartida por Gastos e Ingresos).
  static final balanceTabs = GlobalKey(debugLabel: 'showcase_balanceTabs');
  static final gastosHeader = GlobalKey(debugLabel: 'showcase_gastosHeader');
  static final gastosProgramados = GlobalKey(debugLabel: 'showcase_gastosProg');
  static final gastosDesglose = GlobalKey(debugLabel: 'showcase_gastosDesg');
  static final gastosCategorias = GlobalKey(debugLabel: 'showcase_gastosCat');
  static final ingresosHeader = GlobalKey(debugLabel: 'showcase_ingresosHead');

  // Organización (la barra de tabs es compartida por los tres tabs).
  static final orgTabs = GlobalKey(debugLabel: 'showcase_orgTabs');
  static final cuentasTransferir = GlobalKey(debugLabel: 'showcase_cuentasTr');
  static final cuentasPrimera = GlobalKey(debugLabel: 'showcase_cuentasCard');
  static final categoriasIngreso = GlobalKey(debugLabel: 'showcase_catIng');
  static final categoriasGasto = GlobalKey(debugLabel: 'showcase_catGasto');
  static final obligacionesPrimera = GlobalKey(debugLabel: 'showcase_oblig');

  // Usuario (mock).
  static final usuarioInfo = GlobalKey(debugLabel: 'showcase_usuarioInfo');

  /// Pasos de [pantalla] en orden de aparición: primero los de su
  /// contenido, y al final el botón central y la barra de navegación.
  static List<GlobalKey> pasosDe(ShowcasePantalla pantalla) => [
    ...switch (pantalla) {
      ShowcasePantalla.resumen => [
        resumenBalance,
        resumenGrafico,
        resumenPeriodo,
      ],
      ShowcasePantalla.balanceGastos => [
        balanceTabs,
        gastosHeader,
        gastosProgramados,
        gastosDesglose,
        gastosCategorias,
      ],
      ShowcasePantalla.balanceIngresos => [balanceTabs, ingresosHeader],
      ShowcasePantalla.orgCuentas => [
        orgTabs,
        cuentasTransferir,
        cuentasPrimera,
      ],
      ShowcasePantalla.orgCategorias => [
        orgTabs,
        categoriasIngreso,
        categoriasGasto,
      ],
      ShowcasePantalla.orgObligaciones => [orgTabs, obligacionesPrimera],
      ShowcasePantalla.usuario => [usuarioInfo],
    },
    // Usuario no muestra el botón central (ver RootShell).
    if (pantalla != ShowcasePantalla.usuario) botonCentral,
    barraNavegacion,
  ];

  /// Primer paso de cada pantalla (ahí no se ofrece "Anterior").
  static bool esPrimero(GlobalKey key) =>
      ShowcasePantalla.values.any((p) => pasosDe(p).first == key);

  /// Último paso de todas las pantallas (ahí el botón dice "Listo").
  static bool esUltimo(GlobalKey key) => key == barraNavegacion;
}
