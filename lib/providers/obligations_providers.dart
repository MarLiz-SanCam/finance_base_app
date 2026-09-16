import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import 'database_provider.dart';

final obligationsActivasStreamProvider =
    StreamProvider.autoDispose<List<Obligation>>((ref) {
      return ref.watch(obligationsRepositoryProvider).watchActivas();
    });

final obligationsTodasStreamProvider =
    StreamProvider.autoDispose<List<Obligation>>((ref) {
      return ref.watch(obligationsRepositoryProvider).watchAll();
    });

/// Transacciones `pendiente` (generadas por el motor de obligaciones,
/// todavía sin confirmar), próximas primero por fecha de vencimiento. Al
/// confirmar o cancelar una, esta lista se actualiza sola: es un stream
/// real sobre la tabla, ya no un cálculo heurístico en memoria.
final transaccionesPendientesProvider =
    StreamProvider.autoDispose<List<Transaction>>((ref) {
      return ref.watch(transactionsRepositoryProvider).watchPendientes();
    });
