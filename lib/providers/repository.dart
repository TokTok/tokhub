import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:github/github.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tokhub/logger.dart';
import 'package:tokhub/models/github.dart';
import 'package:tokhub/providers/github.dart';
import 'package:tokhub/providers/objectbox.dart';
import 'package:tokhub/providers/pull_request.dart';

part 'repository.g.dart';

const _logger = Logger(['RepositoryProvider']);

@riverpod
Future<List<StoredRepository>> repositories(Ref ref) async {
  final store = await ref.watch(objectBoxProvider.future);
  final box = store.box<StoredRepository>();
  final stored = box.getAll();
  if (stored.isNotEmpty) {
    return stored;
  }
  final repos = await ref.watch(_githubRepositoriesProvider.future);
  box.putMany(await Future.wait(repos.map((repo) async {
    final sr = StoredRepository()..data = repo;
    sr.pullRequests.addAll(await ref.watch(pullRequestsProvider(sr).future));
    return sr;
  })));
  return box.getAll();
}

@riverpod
Future<List<Repository>> _githubRepositories(Ref ref) async {
  final client = await ref.watch(githubClientProvider.future);
  if (client == null) {
    return const [];
  }

  _logger.d('Fetching repositories');
  return client.repositories.listOrganizationRepositories('TokTok').toList();
}
