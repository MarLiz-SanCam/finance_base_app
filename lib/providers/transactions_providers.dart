import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/db/enums.dart';
import 'database_provider.dart';

final transactionsStreamProvider =
    StreamProvider.autoDispose<List<Transaction>>((ref) {
      return ref.watch(transactionsRepositoryProvider).watchAll();
    });

final transactionsByTypeStreamProvider = StreamProvider.autoDispose
    .family<List<Transaction>, TransactionType>((ref, type) {
      return ref.watch(transactionsRepositoryProvider).watchByType(type);
    });

final transactionsByAccountStreamProvider = StreamProvider.autoDispose
    .family<List<Transaction>, String>((ref, accountId) {
      return ref
          .watch(transactionsRepositoryProvider)
          .watchByAccount(accountId);
    });

final transactionsByObligationStreamProvider = StreamProvider.autoDispose
    .family<List<Transaction>, String>((ref, obligationId) {
      return ref
          .watch(transactionsRepositoryProvider)
          .watchByObligation(obligationId);
    });
