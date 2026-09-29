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
/// junto con lo gastado en la quincena en curso contra su presupuesto.
class CategoriaGastoResumen {
  const CategoriaGastoResumen({
    required this.category,
    required this.esFija,
    required this.gastadoEnLaQuincena,
  });

  final Category category;
  final bool esFija;
  final int gastadoEnLaQuincena;
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
/// por fecha de vencimiento. Incluye pendientes de cualquier fecha (pasada o
/// futura); para solo los de la quincena vigente ver
/// [gastosProximosAVencerQuincenaProvider].
final gastosProximosAVencerProvider =
    Provider.autoDispose<AsyncValue<List<Transaction>>>((ref) {
      final pendientes = ref.watch(transaccionesPendientesProvider);
      return pendientes.whenData(
        (lista) =>
            lista.where((t) => t.type == TransactionType.gasto).toList(),
      );
    });

/// [gastosProximosAVencerProvider] filtrado a los que vencen dentro de la
/// quincena vigente — la lista que se muestra directamente en Balance >
/// Gastos ("Programados por vencer"), a diferencia de Pendientes que
/// muestra todo el histórico sin filtrar por fecha.
final gastosProximosAVencerQuincenaProvider =
    Provider.autoDispose<AsyncValue<List<Transaction>>>((ref) {
      final periodo = PeriodoQuincenal.actual();
      final pendientes = ref.watch(gastosProximosAVencerProvider);
      return pendientes.whenData(
        (lista) => lista
            .where(
              (t) =>
                  !t.dueDate.isBefore(periodo.inicio) &&
                  t.dueDate.isBefore(periodo.finExclusivo),
            )
            .toList(),
      );
    });

/// Categorías de gasto marcadas como fijas (tienen una obligación
/// fija/progresiva activa asociada) o variables, con su avance de
/// presupuesto en la quincena en curso.
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
      final periodo = PeriodoQuincenal.actual();
      return Future.wait(
        categorias.map((categoria) async {
          final gastado = await categoriesRepo.gastadoEnRango(
            categoria.id,
            desde: periodo.inicio,
            hasta: periodo.finExclusivo,
          );
          return CategoriaGastoResumen(
            category: categoria,
            esFija: categoriasConObligacionFija.contains(categoria.id),
            gastadoEnLaQuincena: gastado,
          );
        }),
      );
    });

/// Modo de agrupación del gráfico de línea del dashboard de egresos.
enum EgresosChartMode { quincenal, mensual, anual }

final egresosChartModeProvider = StateProvider.autoDispose<EgresosChartMode>(
  (ref) => EgresosChartMode.quincenal,
);

/// Gasto por día de la quincena en curso, para la vista quincenal del
/// gráfico.
final gastoPorDiaDeLaQuincenaProvider = FutureProvider.autoDispose<List<int>>((
  ref,
) {
  ref.watch(transactionsStreamProvider);
  final periodo = PeriodoQuincenal.actual();
  return ref
      .watch(transactionsRepositoryProvider)
      .gastoPorDiaEnRango(desde: periodo.inicio, hasta: periodo.finExclusivo);
});

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
