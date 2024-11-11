import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:github/github.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tokhub/logger.dart';
import 'package:tokhub/models/github.dart';
import 'package:tokhub/objectbox.g.dart';
import 'package:tokhub/providers/github.dart';
import 'package:tokhub/providers/objectbox.dart';

part 'pull_request.g.dart';

const _logger = Logger(['PullRequestProvider']);

@riverpod
Future<StoredPullRequest> pullRequest(
    Ref ref, StoredRepository repo, int number) async {
  final store = await ref.watch(objectBoxProvider.future);
  final box = store.box<StoredPullRequest>();
  final fetched = (await box
          .query(StoredPullRequest_.repo.equals(repo.id))
          .build()
          .findAsync())
      .where((pr) => pr.data.number == number && pr.data.mergeableState != '')
      .toList(growable: false);
  if (fetched.isNotEmpty) {
    _logger.v('Found stored pull request for ${repo.data.slug()}#$number '
        '(${fetched.first.data.mergeableState})');
    return fetched.first;
  }
  return box.get(
      await ref.watch(_fetchAndStorePullRequestProvider(repo, number).future))!;
}

Future<void> pullRequestRefresh(
  WidgetRef ref,
  StoredRepository repo,
  StoredPullRequest pullRequest,
) async {
  ref.invalidate(
      _fetchAndStorePullRequestProvider(repo, pullRequest.data.number));
  await ref.watch(
      _fetchAndStorePullRequestProvider(repo, pullRequest.data.number).future);
}

@riverpod
Future<List<StoredPullRequest>> pullRequests(
    Ref ref, StoredRepository repo) async {
  final store = await ref.watch(objectBoxProvider.future);
  final box = store.box<StoredPullRequest>();
  final fetched =
      box.query(StoredPullRequest_.repo.equals(repo.id)).build().find();
  if (fetched.isNotEmpty) {
    _logger.v('Found ${fetched.length} '
        'stored pull requests for ${repo.data.slug()}');
    return fetched;
  }

  final ids = await ref.watch(_fetchAndStorePullRequestsProvider(repo).future);
  return box
      .getMany(ids)
      .whereType<StoredPullRequest>()
      .toList(growable: false);
}

Future<void> pullRequestsRefresh(WidgetRef ref, StoredRepository repo) async {
  ref.invalidate(_fetchAndStorePullRequestsProvider(repo));
  await ref.watch(_fetchAndStorePullRequestsProvider(repo).future);
}

@riverpod
Future<int> _fetchAndStorePullRequest(
    Ref ref, StoredRepository repo, int number) async {
  final store = await ref.watch(objectBoxProvider.future);
  final box = store.box<StoredPullRequest>();

  final pr = await ref.watch(_githubPullRequestProvider(repo, number).future);
  final id = box.put(StoredPullRequest()
    ..data = pr
    ..repo.target = repo);
  _logger.v('Stored pull request: ${repo.data.slug()}#$number');

  return id;
}

@riverpod
Future<List<int>> _fetchAndStorePullRequests(
    Ref ref, StoredRepository repo) async {
  final store = await ref.watch(objectBoxProvider.future);
  final box = store.box<StoredPullRequest>();

  final prs = (await ref.watch(_githubPullRequestsProvider(repo).future))
      .map((pr) => StoredPullRequest()
        ..data = pr
        ..repo.target = repo)
      .toList(growable: false);
  final ids = box.putMany(prs);
  _logger.v('Stored pull requests: ${ids.length}');

  return ids;
}

@riverpod
Future<MinimalPullRequest> _githubPullRequest(
    Ref ref, StoredRepository repo, int number) async {
  final slug = repo.data.slug();
  final client = await ref.watch(githubClientProvider.future);
  if (client == null) {
    throw StateError('No client available');
  }

  _logger.d('Fetching pull request $slug#$number');
  return client.getJSON(
    '/repos/$slug/pulls/$number',
    convert: MinimalPullRequest.fromJson,
    statusCode: StatusCodes.OK,
  );
}

@riverpod
Future<List<MinimalPullRequest>> _githubPullRequests(
    Ref ref, StoredRepository repo) async {
  final slug = repo.data.slug();
  final client = await ref.watch(githubClientProvider.future);
  if (client == null) {
    return const [];
  }

  _logger.d('Fetching pull requests for $slug');
  return client.pullRequests
      .list(slug)
      .map((pr) =>
          MinimalPullRequest.fromJson(jsonDecode(jsonEncode(pr.toJson()))))
      .toList();
}
