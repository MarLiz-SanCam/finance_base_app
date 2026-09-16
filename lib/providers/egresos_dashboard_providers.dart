import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/periodo_quincenal.dart';
import '../data/db/app_database.dart';
import '../data/db/enums.dart';
import 'categories_providers.dart';
import 'database_provider.dart';
import 'obligations_providers.dart';
import 'transactions_providers.dart';

/// Vista de una categoría de gasto para el dashboard: si tiene una
/// obligación fija/progresiva activa asociada ("fija") o no ("variable"),
/// junto con lo gastado en el mes en curso contra su presupuesto.
class CategoriaGastoResumen {
  const CategoriaGastoResumen({
    required this.category,
    required this.esFija,
    required this.gastadoEnElMes,
  });

  final Category category;
  final bool esFija;
  final int gastadoEnElMes;
}

/// Total gastado (transacciones type=gasto) en la quincena actual.
final gastoQuincenaActualProvider = FutureProvider.autoDispose<int>((ref) {
  ref.watch(transactionsStreamProvider);
  final periodo = PeriodoQuincenal.actual();
  return ref
      .watch(transactionsRepositoryProvider)
      .totalGastoEnRango(desde: periodo.inicio, hasta: periodo.finExclusivo);
});

/// Gastos (transacciones) ya realizados dentro de la quincena actual.
final gastosRealizadosQuincenaProvider =
    FutureProvider.autoDispose<List<Transaction>>((ref) {
      ref.watch(transactionsStreamProvider);
      final periodo = PeriodoQuincenal.actual();
      return ref
          .watch(transactionsRepositoryProvider)
          .gastosEnRango(desde: periodo.inicio, hasta: periodo.finExclusivo);
    });

/// Transacciones `pendiente` de tipo gasto (pagos de obligaciones fijas o
/// progresivas todavía sin confirmar) —es decir,
/// [transaccionesPendientesProvider] sin los ingresos fijos—, ya ordenadas
/// por fecha de vencimiento.
final gastosProximosAVencerProvider =
    Provider.autoDispose<AsyncValue<List<Transaction>>>((ref) {
      final pendientes = ref.watch(transaccionesPendientesProvider);
      return pendientes.whenData(
        (lista) =>
            lista.where((t) => t.type == TransactionType.gasto).toList(),
      );
    });

/// Categorías de gasto marcadas como fijas (tienen una obligación
/// fija/progresiva activa asociada) o variables, con su avance de
/// presupuesto en el mes en curso.
final categoriasGastoResumenProvider =
    FutureProvider.autoDispose<List<CategoriaGastoResumen>>((ref) async {
      final categorias = await ref.watch(
        categoriesByTypeStreamProvider(CategoryType.gasto).future,
      );
      final obligacionesActivas = await ref.watch(
        obligationsActivasStreamProvider.future,
      );
      final categoriasConObligacionFija = obligacionesActivas
          .where((o) => o.type != ObligationType.ingresoFijo)
          .map((o) => o.categoryId)
          .toSet();

      final categoriesRepo = ref.watch(categoriesRepositoryProvider);
      return Future.wait(
        categorias.map((categoria) async {
          final gastado = await categoriesRepo.gastadoEnElMes(categoria.id);
          return CategoriaGastoResumen(
            category: categoria,
            esFija: categoriasConObligacionFija.contains(categoria.id),
            gastadoEnElMes: gastado,
          );
        }),
      );
    });

/// Modo de agrupación del gráfico de línea del dashboard de egresos.
enum EgresosChartMode { mensual, anual }

final egresosChartModeProvider = StateProvider.autoDispose<EgresosChartMode>(
  (ref) => EgresosChartMode.mensual,
);

/// Gasto por día del mes en curso, para la vista mensual del gráfico.
final gastoPorDiaDelMesProvider = FutureProvider.autoDispose<List<int>>((ref) {
  ref.watch(transactionsStreamProvider);
  return ref
      .watch(transactionsRepositoryProvider)
      .gastoPorDiaDelMes(DateTime.now());
});

/// Gasto por mes del año en curso, para la vista anual del gráfico.
final gastoPorMesDelAnioProvider = FutureProvider.autoDispose<List<int>>((
  ref,
) {
  ref.watch(transactionsStreamProvider);
  return ref
      .watch(transactionsRepositoryProvider)
      .gastoPorMesDelAnio(DateTime.now().year);
});
