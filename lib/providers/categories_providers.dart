import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/db/enums.dart';
import 'database_provider.dart';

final categoriesStreamProvider = StreamProvider.autoDispose<List<Category>>((
  ref,
) {
  return ref.watch(categoriesRepositoryProvider).watchAll();
});

final categoriesByTypeStreamProvider = StreamProvider.autoDispose
    .family<List<Category>, CategoryType>((ref, type) {
      return ref.watch(categoriesRepositoryProvider).watchByType(type);
    });
