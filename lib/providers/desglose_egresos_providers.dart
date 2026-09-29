import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/periodo_quincenal.dart';
import '../data/db/app_database.dart';
import '../data/db/enums.dart';
import 'categories_providers.dart';
import 'database_provider.dart';
import 'transactions_providers.dart';

/// Agrupación de un gasto pagado según la obligación que lo originó (o
/// ninguna): base del desglose de egresos por periodo.
enum GrupoGasto { fijo, progresivo, variable }

GrupoGasto _grupoDeObligacion(ObligationType? tipo) {
  switch (tipo) {
    case ObligationType.gastoFijo:
      return GrupoGasto.fijo;
    case ObligationType.progresivo:
      return GrupoGasto.progresivo;
    case ObligationType.ingresoFijo:
    case null:
      // ingresoFijo no debería ocurrir en una transacción type=gasto; se
      // trata como variable por seguridad, no debería alcanzarse nunca.
      return GrupoGasto.variable;
  }
}

class GastoConGrupo {
  const GastoConGrupo({required this.transaccion, required this.grupo});

  final Transaction transaccion;
  final GrupoGasto grupo;
}

class CategoriaConSubtotal {
  const CategoriaConSubtotal({
    required this.categoryId,
    required this.nombre,
    required this.totalCentavos,
  });

  final String categoryId;
  final String nombre;
  final int totalCentavos;
}

/// Gastos pagados en la quincena actual, cada uno con su grupo
/// (fijo/progresivo/variable) ya resuelto.
final gastosConGrupoQuincenaProvider =
    FutureProvider.autoDispose<List<GastoConGrupo>>((ref) async {
      ref.watch(transactionsStreamProvider);
      final periodo = PeriodoQuincenal.actual();
      final gastos = await ref
          .watch(transactionsRepositoryProvider)
          .gastosConOrigenEnRango(
            desde: periodo.inicio,
            hasta: periodo.finExclusivo,
          );
      return [
        for (final gasto in gastos)
          GastoConGrupo(
            transaccion: gasto.transaccion,
            grupo: _grupoDeObligacion(gasto.tipoObligacion),
          ),
      ];
    });

/// Total gastado por grupo en la quincena actual.
final totalesPorGrupoProvider =
    FutureProvider.autoDispose<Map<GrupoGasto, int>>((ref) async {
      final gastos = await ref.watch(gastosConGrupoQuincenaProvider.future);
      final totales = {for (final grupo in GrupoGasto.values) grupo: 0};
      for (final gasto in gastos) {
        totales[gasto.grupo] = totales[gasto.grupo]! + gasto.transaccion.amount;
      }
      return totales;
    });

/// Total presupuestado (gastos con obligación fija o progresiva) vs. no
/// planeado (gastos sueltos, sin obligación — "gastos hormiga") en la
/// quincena actual. Alimenta el encabezado de Balance > Gastos.
final presupuestadoVsNoPlaneadoProvider =
    FutureProvider.autoDispose<({int presupuestado, int noPlaneado})>((
      ref,
    ) async {
      final totales = await ref.watch(totalesPorGrupoProvider.future);
      return (
        presupuestado:
            (totales[GrupoGasto.fijo] ?? 0) +
            (totales[GrupoGasto.progresivo] ?? 0),
        noPlaneado: totales[GrupoGasto.variable] ?? 0,
      );
    });

/// Categorías con subtotal dentro de un grupo, en la quincena actual,
/// ordenadas de mayor a menor gasto.
final categoriasPorGrupoProvider = FutureProvider.autoDispose
    .family<List<CategoriaConSubtotal>, GrupoGasto>((ref, grupo) async {
      final gastos = await ref.watch(gastosConGrupoQuincenaProvider.future);
      final categorias = await ref.watch(categoriesStreamProvider.future);
      final nombrePorId = {for (final c in categorias) c.id: c.name};

      final subtotales = <String, int>{};
      for (final gasto in gastos.where((g) => g.grupo == grupo)) {
        // gastosConOrigenEnRango solo trae type=gasto, que siempre exige
        // categoría (solo las transferencias la dejan en null).
        final categoryId = gasto.transaccion.categoryId!;
        subtotales[categoryId] =
            (subtotales[categoryId] ?? 0) + gasto.transaccion.amount;
      }

      final resultado = [
        for (final entrada in subtotales.entries)
          CategoriaConSubtotal(
            categoryId: entrada.key,
            nombre: nombrePorId[entrada.key] ?? 'Sin categoría',
            totalCentavos: entrada.value,
          ),
      ]..sort((a, b) => b.totalCentavos.compareTo(a.totalCentavos));
      return resultado;
    });

/// Transacciones de una categoría dentro de un grupo, en la quincena
/// actual, más recientes primero.
final transaccionesPorCategoriaYGrupoProvider = FutureProvider.autoDispose
    .family<List<Transaction>, ({GrupoGasto grupo, String categoryId})>((
      ref,
      params,
    ) async {
      final gastos = await ref.watch(gastosConGrupoQuincenaProvider.future);
      return gastos
          .where(
            (g) =>
                g.grupo == params.grupo &&
                g.transaccion.categoryId == params.categoryId,
          )
          .map((g) => g.transaccion)
          .toList()
        ..sort((a, b) => b.paymentDate!.compareTo(a.paymentDate!));
    });
