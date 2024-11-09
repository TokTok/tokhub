import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:github/github.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tokhub/models/github.dart';
import 'package:tokhub/objectbox.g.dart';
import 'package:tokhub/providers/objectbox.dart';
import 'package:tokhub/providers/settings.dart';

part 'github.g.dart';

@Riverpod(keepAlive: true)
Future<CurrentUser?> currentUser(Ref ref) async {
  final client = await ref.watch(githubClientProvider.future);
  if (client == null) {
    return null;
  }

  debugPrint('Fetching current user');
  return client.users.getCurrentUser();
}

// Provider for the GitHub client.
@riverpod
Future<GitHub?> githubClient(Ref ref) async {
  final token = await ref.watch(githubTokenProvider.future);
  if (token == null) {
    return null;
  }

  return GitHub(auth: Authentication.withToken(token));
}

// Dedicated provider for the token.
@riverpod
Future<String?> githubToken(Ref ref) async {
  final settings = await ref.watch(settingsProvider.future);
  return settings.token;
}

@riverpod
Future<List<PullRequest>> pullRequests(Ref ref, RepositorySlug slug) async {
  final client = await ref.watch(githubClientProvider.future);
  if (client == null) {
    return const [];
  }

  debugPrint('Fetching pull requests for $slug');
  return client.pullRequests.list(slug).toList();
}

@riverpod
Future<List<Repository>> repositories(Ref ref) async {
  final client = await ref.watch(githubClientProvider.future);
  if (client == null) {
    return const [];
  }

  debugPrint('Fetching repositories');
  return client.repositories.listOrganizationRepositories('TokTok').toList();
}

@riverpod
Future<List<StoredPullRequest>> storedPullRequests(
    Ref ref, StoredRepository repo) async {
  final store = await ref.watch(objectBoxProvider.future);
  final box = store.box<StoredPullRequests>();
  final fetched =
      box.query(StoredPullRequests_.repo.equals(repo.id)).build().find();
  if (fetched.isNotEmpty) {
    debugPrint('Found ${fetched.first.pullRequests.length} '
        'stored pull requests for ${repo.data.slug()}');
    return fetched.first.pullRequests;
  }
  final prs = await ref.watch(pullRequestsProvider(repo.data.slug()).future);

  final sprs = prs
      .map((pr) => StoredPullRequest()
        ..data = pr
        ..repo.target = repo)
      .toList(growable: false);
  final sprBox = store.box<StoredPullRequest>();
  sprBox.putMany(sprs);

  box.put(StoredPullRequests()
    ..repo.target = repo
    ..pullRequests.addAll(
        sprBox.query(StoredPullRequest_.repo.equals(repo.id)).build().find()));
  final stored =
      box.query(StoredPullRequests_.repo.equals(repo.id)).build().find();
  debugPrint('Stored pull requests: ${stored.first.pullRequests.length}');
  return stored.first.pullRequests;
}

@riverpod
Future<List<StoredRepository>> storedRepositories(Ref ref) async {
  final store = await ref.watch(objectBoxProvider.future);
  final box = store.box<StoredRepository>();
  final stored = await (() async {
    final stored = box.getAll();
    if (stored.isNotEmpty) {
      return stored;
    }
    final repos = await ref.watch(repositoriesProvider.future);
    box.putMany(repos
        .map((repo) => StoredRepository()..data = repo)
        .toList(growable: false));
    return box.getAll();
  })();
  stored.sort((a, b) => a.data.name.compareTo(b.data.name));
  return stored;
}
