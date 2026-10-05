import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import 'database_provider.dart';

final accountsStreamProvider = StreamProvider.autoDispose<List<Account>>((ref) {
  return ref.watch(accountsRepositoryProvider).watchAll();
});
