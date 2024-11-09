import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:github/github.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tokhub/models/github.dart';
import 'package:tokhub/objectbox.g.dart';
import 'package:tokhub/providers/objectbox.dart';
import 'package:tokhub/providers/settings.dart';

part 'github.g.dart';

@riverpod
Future<CurrentUser?> currentUser(Ref ref) async {
  final client = await ref.watch(_githubClientProvider.future);
  if (client == null) {
    return null;
  }

  debugPrint('Fetching current user');
  return client.users.getCurrentUser();
}

@riverpod
Future<List<StoredPullRequest>> pullRequests(
    Ref ref, StoredRepository repo) async {
  final store = await ref.watch(objectBoxProvider.future);
  final box = store.box<StoredPullRequest>();
  final fetched =
      box.query(StoredPullRequest_.repo.equals(repo.id)).build().find();
  if (fetched.isNotEmpty) {
    debugPrint('Found ${fetched.length} '
        'stored pull requests for ${repo.data.slug()}');
    return fetched;
  }
  final prs =
      await ref.watch(_githubPullRequestsProvider(repo.data.slug()).future);

  final sprs = await Future.wait(prs.map((pr) async => StoredPullRequest()
    ..data = (await ref
        .watch(_githubPullRequestProvider(repo.data.slug(), pr.number!).future))
    ..repo.target = repo));
  final sprBox = store.box<StoredPullRequest>();
  sprBox.putMany(sprs);

  debugPrint('Stored pull requests: ${sprs.length}');
  return sprs;
}

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

// Provider for the GitHub client.
@riverpod
Future<GitHub?> _githubClient(Ref ref) async {
  final token = await ref.watch(_githubTokenProvider.future);
  if (token == null) {
    return null;
  }

  return GitHub(auth: Authentication.withToken(token));
}

@riverpod
Future<PullRequest> _githubPullRequest(
    Ref ref, RepositorySlug slug, int number) async {
  final client = await ref.watch(_githubClientProvider.future);
  if (client == null) {
    throw StateError('No client available');
  }

  debugPrint('Fetching pull request $slug#$number');
  return client.pullRequests.get(slug, number);
}

@riverpod
Future<List<PullRequest>> _githubPullRequests(
    Ref ref, RepositorySlug slug) async {
  final client = await ref.watch(_githubClientProvider.future);
  if (client == null) {
    return const [];
  }

  debugPrint('Fetching pull requests for $slug');
  return client.pullRequests.list(slug).toList();
}

@riverpod
Future<List<Repository>> _githubRepositories(Ref ref) async {
  final client = await ref.watch(_githubClientProvider.future);
  if (client == null) {
    return const [];
  }

  debugPrint('Fetching repositories');
  return client.repositories.listOrganizationRepositories('TokTok').toList();
}

// Dedicated provider for the token.
@riverpod
Future<String?> _githubToken(Ref ref) async {
  final settings = await ref.watch(settingsProvider.future);
  return settings.token;
}
