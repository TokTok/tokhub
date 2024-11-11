import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:github/github.dart' show PaginationHelper;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tokhub/logger.dart';
import 'package:tokhub/models/github.dart';
import 'package:tokhub/objectbox.g.dart';
import 'package:tokhub/providers/github.dart';
import 'package:tokhub/providers/objectbox.dart';
import 'package:tokhub/providers/pull_request.dart';

part 'repository.g.dart';

const _logger = Logger(['RepositoryProvider']);

@riverpod
Future<List<MinimalRepository>> repositories(Ref ref, {required String org}) async {
  final store = await ref.watch(objectBoxProvider.future);
  final box = store.box<MinimalRepository>();
  final stored =
      box.query(MinimalRepository_.owner.equals(org)).build().find();
  if (stored.isNotEmpty) {
    return stored;
  }
  await ref.watch(_fetchAndStoreRepositoriesProvider(org: org).future);
  return box.query(MinimalRepository_.owner.equals(org)).build().find();
}

Future<void> repositoriesRefresh(WidgetRef ref, {required String org}) async {
  ref.invalidate(_fetchAndStoreRepositoriesProvider(org: org));
  await ref.watch(_fetchAndStoreRepositoriesProvider(org: org).future);
}

@riverpod
Future<List<int>> _fetchAndStoreRepositories(Ref ref, {required String org}) async {
  final repos = await ref.watch(_githubRepositoriesProvider(org: org).future);
  final store = await ref.watch(objectBoxProvider.future);
  final box = store.box<MinimalRepository>();
  final ids = box.putMany(await Future.wait(repos.map((repo) async {
    repo.pullRequests
        .addAll(await ref.watch(pullRequestsProvider(repo).future));
    return repo;
  })));
  _logger.v('Stored ${ids.length} repositories');
  return ids;
}

@riverpod
Future<List<MinimalRepository>> _githubRepositories(Ref ref, {required String org}) async {
  final client = await ref.watch(githubClientProvider.future);
  if (client == null) {
    return const [];
  }

  _logger.d('Fetching repositories');
  return PaginationHelper(client)
      .objects<Map<String, dynamic>, MinimalRepository>(
        'GET',
        '/orgs/$org/repos',
        MinimalRepository.fromJson,
      )
      .toList();
}
