import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/periodo_quincenal.dart';
import 'database_provider.dart';
import 'transactions_providers.dart';

/// Total ingresado (transacciones type=ingreso, pagadas) en la quincena
/// actual — alimenta el encabezado de Balance > Ingresos.
final ingresoQuincenaActualProvider = FutureProvider.autoDispose<int>((ref) {
  ref.watch(transactionsStreamProvider);
  final periodo = PeriodoQuincenal.actual();
  return ref
      .watch(transactionsRepositoryProvider)
      .totalIngresoEnRango(desde: periodo.inicio, hasta: periodo.finExclusivo);
});
