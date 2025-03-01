import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:github/github.dart' show PaginationHelper;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tokhub/db/database.dart';
import 'package:tokhub/logger.dart';
import 'package:tokhub/providers/database.dart';
import 'package:tokhub/providers/github.dart';

part 'repos.g.dart';

const _logger = Logger(['RepositoryProvider']);

@riverpod
Future<List<MinimalRepositoryData>> repositories(Ref ref, String org) async {
  final db = await ref.watch(databaseProvider.future);
  return (db.select(db.minimalRepository)
        ..orderBy([(r) => OrderingTerm(expression: r.fullName)]))
      .get();
}

Future<List<MinimalRepositoryData>> repositoriesRefresh(
    WidgetRef ref, String org) async {
  ref.invalidate(_fetchAndStoreRepositoriesProvider(org));
  await ref.watch(_fetchAndStoreRepositoriesProvider(org).future);
  return ref.refresh(repositoriesProvider(org).future);
}

@riverpod
Future<void> _fetchAndStoreRepositories(Ref ref, String org) async {
  final repos = await ref.watch(_githubRepositoriesProvider(org).future);
  final db = await ref.watch(databaseProvider.future);

  await db.batch((b) {
    b.insertAllOnConflictUpdate(db.minimalRepository, repos);
  });

  _logger.v('Stored ${repos.length} repositories');
}

@riverpod
Future<List<MinimalRepositoryData>> _githubRepositories(
    Ref ref, String org) async {
  final client = await ref.watch(githubClientProvider.future);
  if (client == null) {
    _logger.e('GitHub: no client available');
    return const [];
  }

  final repos = await PaginationHelper(client)
      .objects<Map<String, dynamic>, MinimalRepositoryData>(
        'GET',
        '/orgs/$org/repos',
        _logger.catching(MinimalRepositoryData.fromJson),
      )
      .toList();
  _logger.d('Fetched ${repos.length} repositories for $org');
  return repos;
}
