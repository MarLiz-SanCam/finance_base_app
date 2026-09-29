import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/periodo_quincenal.dart';
import '../data/db/app_database.dart';
import '../data/db/enums.dart';
import 'database_provider.dart';
import 'transactions_providers.dart';

final categoriesStreamProvider = StreamProvider.autoDispose<List<Category>>((
  ref,
) {
  return ref.watch(categoriesRepositoryProvider).watchAll();
});

final categoriesByTypeStreamProvider = StreamProvider.autoDispose
    .family<List<Category>, CategoryType>((ref, type) {
      return ref.watch(categoriesRepositoryProvider).watchByType(type);
    });

/// Una categoría junto con lo movido en ella durante la quincena en curso:
/// ingresado si es de tipo `ingreso`, gastado si es de tipo `gasto`. Base de
/// las tarjetas del tab "Categorías" de Organización.
class CategoriaConMontoQuincena {
  const CategoriaConMontoQuincena({
    required this.category,
    required this.montoQuincena,
  });

  final Category category;
  final int montoQuincena;
}

final categoriasConMontoQuincenaProvider =
    FutureProvider.autoDispose<List<CategoriaConMontoQuincena>>((ref) async {
      ref.watch(transactionsStreamProvider);
      final categorias = await ref.watch(categoriesStreamProvider.future);
      final categoriesRepo = ref.watch(categoriesRepositoryProvider);
      final periodo = PeriodoQuincenal.actual();

      return Future.wait(
        categorias.map((categoria) async {
          final monto = categoria.type == CategoryType.ingreso
              ? await categoriesRepo.ingresadoEnRango(
                  categoria.id,
                  desde: periodo.inicio,
                  hasta: periodo.finExclusivo,
                )
              : await categoriesRepo.gastadoEnRango(
                  categoria.id,
                  desde: periodo.inicio,
                  hasta: periodo.finExclusivo,
                );
          return CategoriaConMontoQuincena(
            category: categoria,
            montoQuincena: monto,
          );
        }),
      );
    });
