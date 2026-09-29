import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/repositories/accounts_repository.dart';
import '../data/repositories/categories_repository.dart';
import '../data/repositories/local_identity_repository.dart';
import '../data/repositories/obligations_repository.dart';
import '../data/repositories/showcase_progress_repository.dart';
import '../data/repositories/transactions_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final localIdentityRepositoryProvider = Provider<LocalIdentityRepository>((
  ref,
) {
  return LocalIdentityRepository(ref.watch(appDatabaseProvider));
});

final showcaseProgressRepositoryProvider = Provider<ShowcaseProgressRepository>(
  (ref) {
    return ShowcaseProgressRepository(ref.watch(appDatabaseProvider));
  },
);

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  return AccountsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(localIdentityRepositoryProvider),
  );
});

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(localIdentityRepositoryProvider),
  );
});

final obligationsRepositoryProvider = Provider<ObligationsRepository>((ref) {
  return ObligationsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(localIdentityRepositoryProvider),
  );
});

final transactionsRepositoryProvider = Provider<TransactionsRepository>((
  ref,
) {
  return TransactionsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(accountsRepositoryProvider),
    ref.watch(obligationsRepositoryProvider),
    ref.watch(localIdentityRepositoryProvider),
  );
});
