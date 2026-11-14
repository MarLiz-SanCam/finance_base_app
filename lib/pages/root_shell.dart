import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:showcaseview/showcaseview.dart';

import '../core/components/app_showcase.dart';
import '../core/components/bottomNavBar.dart';
import '../core/components/rounded_body.dart';
import '../core/showcase/showcase_keys.dart';
import '../data/db/enums.dart';
import '../providers/database_provider.dart';
import 'balance/balance_page.dart';
import 'categorias/form_categoria.dart';
import 'cuentas/form_cuenta.dart';
import 'home/home.dart';
import 'home/widgets/registro_rapido.dart';
import 'obligaciones/form_obligacion.dart';
import 'organizacion/organizacion_page.dart';
import 'usuario/usuario_page.dart';

/// Cascarón de navegación: Resumen, Balance, Organización y Usuario (mock),
/// con una barra inferior de dos ítems por lado (Resumen/Balance a la
/// izquierda, Organización/Usuario a la derecha) y un botón central "+" que
/// registra según el contexto activo (la pestaña principal y, en
/// Balance/Organización, el tab interno). Por eso los [TabController] de
/// Balance y Organización viven aquí en vez de en cada página: es la única
/// forma en que el botón central sabe qué tab interno está activo.
///
/// También es dueño del showcase (ayuda guiada): registra el
/// [ShowcaseView], arranca el de la pantalla activa cuando se toca el botón
/// de ayuda del appbar y la primera vez que se entra a cada pantalla/tab.
class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell>
    with TickerProviderStateMixin {
  int _indice = 0;

  /// Pantalla cuyo showcase se está mostrando, para marcarla como vista al
  /// terminar o al omitirlo.
  ShowcasePantalla? _showcaseEnCurso;

  /// Última pantalla evaluada para el arranque automático; evita repetirlo
  /// mientras el [TabController] emite varias notificaciones por cambio.
  ShowcasePantalla? _ultimaEvaluada;

  Timer? _timerShowcase;

  late final TabController _balanceTabController = TabController(
    length: 2,
    vsync: this,
  );
  late final TabController _organizacionTabController = TabController(
    length: 3,
    vsync: this,
  );

  static final _items = [
    AppBottomNavItem(icon: Symbols.monitoring, label: 'Resumen'),
    AppBottomNavItem(icon: Icons.swap_vert, label: 'Balance'),
    AppBottomNavItem(icon: Icons.dashboard_outlined, label: 'Organización'),
    AppBottomNavItem(icon: Icons.person_outline, label: 'Usuario'),
  ];

  /// Resumen y Balance a la izquierda de la muesca; Organización y Usuario
  /// a la derecha (ver [AppBottomNavBar.centerAfterIndex]).
  static const _centerAfterIndex = 1;

  /// Pantalla o tab activo, que es la unidad del showcase.
  ShowcasePantalla get _pantallaActiva => switch (_indice) {
    0 => ShowcasePantalla.resumen,
    1 =>
      _balanceTabController.index == 0
          ? ShowcasePantalla.balanceGastos
          : ShowcasePantalla.balanceIngresos,
    2 => switch (_organizacionTabController.index) {
      0 => ShowcasePantalla.orgCuentas,
      1 => ShowcasePantalla.orgCategorias,
      _ => ShowcasePantalla.orgObligaciones,
    },
    _ => ShowcasePantalla.usuario,
  };

  @override
  void initState() {
    super.initState();
    ShowcaseView.register(
      onFinish: _marcarShowcaseVisto,
      onDismiss: (_) => _marcarShowcaseVisto(),
      skipIfTargetNotPresent: true,
      enableAutoScroll: true,
    );
    _balanceTabController.addListener(_alCambiarPantalla);
    _organizacionTabController.addListener(_alCambiarPantalla);
    WidgetsBinding.instance.addPostFrameCallback((_) => _alCambiarPantalla());
  }

  /// Rebuild (el texto del botón central depende de la pantalla) y, si el
  /// showcase de la pantalla nueva no se ha visto, lo arranca tras un
  /// respiro para que termine la animación de tab y carguen los datos.
  void _alCambiarPantalla() {
    final pantalla = _pantallaActiva;
    if (pantalla == _ultimaEvaluada) return;
    _ultimaEvaluada = pantalla;
    if (mounted) setState(() {});
    _timerShowcase?.cancel();
    _timerShowcase = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted || _pantallaActiva != pantalla) return;
      final visto = await ref
          .read(showcaseProgressRepositoryProvider)
          .fueVisto(pantalla.id, pantalla.version);
      if (!mounted || visto || _pantallaActiva != pantalla) return;
      _iniciarShowcase(pantalla);
    });
  }

  void _iniciarShowcase(ShowcasePantalla pantalla) {
    _showcaseEnCurso = pantalla;
    ShowcaseView.get().startShowCase(ShowcaseKeys.pasosDe(pantalla));
  }

  void _mostrarAyuda() => _iniciarShowcase(_pantallaActiva);

  void _marcarShowcaseVisto() {
    final pantalla = _showcaseEnCurso;
    if (pantalla == null) return;
    _showcaseEnCurso = null;
    ref
        .read(showcaseProgressRepositoryProvider)
        .marcarVisto(pantalla.id, pantalla.version);
  }

  String get _descripcionBotonCentral => switch (_pantallaActiva) {
    ShowcasePantalla.resumen ||
    ShowcasePantalla.balanceGastos => 'Registra un gasto.',
    ShowcasePantalla.balanceIngresos => 'Agrega un ingreso.',
    ShowcasePantalla.orgCuentas => 'Crea una cuenta nueva.',
    ShowcasePantalla.orgCategorias => 'Crea una categoría nueva.',
    ShowcasePantalla.orgObligaciones => 'Crea una obligación nueva.',
    ShowcasePantalla.usuario => '',
  };

  @override
  void dispose() {
    _timerShowcase?.cancel();
    ShowcaseView.get().unregister();
    _balanceTabController.dispose();
    _organizacionTabController.dispose();
    super.dispose();
  }

  /// Índices de tab interno: Balance → 0 Gastos / 1 Ingresos; Organización
  /// → 0 Cuentas / 1 Categorías / 2 Obligaciones.
  void _tocarBotonCentral(BuildContext context) {
    switch (_indice) {
      case 0: // Resumen
        mostrarRegistroRapido(context);
      case 1: // Balance
        mostrarRegistroRapido(
          context,
          tipoInicial: _balanceTabController.index == 0
              ? TransactionType.gasto
              : TransactionType.ingreso,
        );
      case 2: // Organización
        switch (_organizacionTabController.index) {
          case 0:
            mostrarFormularioCuenta(context);
          case 1:
            mostrarFormularioCategoria(context);
          default:
            mostrarFormularioObligacion(context);
        }
      default: // Usuario: mock, todavía sin acción.
    }
  }

  @override
  Widget build(BuildContext context) {
    final paginas = [
      HomePage(onHelp: _mostrarAyuda),
      BalancePage(controller: _balanceTabController, onHelp: _mostrarAyuda),
      OrganizacionPage(
        controller: _organizacionTabController,
        onHelp: _mostrarAyuda,
      ),
      UsuarioPage(onHelp: _mostrarAyuda),
    ];
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.inverseSurface,
      body: AppRoundedBody(
        radius: 50,
        child: IndexedStack(index: _indice, children: paginas),
      ),
      // El botón central se acopla a la muesca de bottomNavigationBar: el
      // framework lo centra y calcula el recorte exacto en vez de que lo
      // hagamos a mano (ver AppBottomNavBar/AppFloatingNavButton). En
      // Usuario (mock, todavía sin nada que registrar) no se muestra: sin
      // FAB, BottomAppBar tampoco talla la muesca.
      floatingActionButton: _indice == _items.length - 1
          ? null
          : AppShowcase(
              showcaseKey: ShowcaseKeys.botonCentral,
              title: 'Botón agregar',
              description: _descripcionBotonCentral,
              borderRadius: 100,
              child: AppFloatingNavButton(
                icon: Icons.add,
                tooltip: 'Agregar',
                onTap: () => _tocarBotonCentral(context),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BottomAppBar(
              color: colorScheme.inverseSurface,
              shape: const CircularNotchedRectangle(),
              notchMargin: 6,
              padding: EdgeInsets.zero,
              elevation: 0,
              height: AppBottomNavBar.trayHeight,
              child: AppShowcase(
                showcaseKey: ShowcaseKeys.barraNavegacion,
                title: 'Navegación',
                description:
                    'Cambia entre Resumen, Balance, Organización y Usuario.',
                borderRadius: 24,
                tooltipPosition: TooltipPosition.top,
                child: AppBottomNavBar(
                  items: _items,
                  currentIndex: _indice,
                  onTap: (i) {
                    setState(() => _indice = i);
                    _alCambiarPantalla();
                  },
                  centerAfterIndex: _centerAfterIndex,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
