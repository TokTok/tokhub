import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:github/github.dart' show StatusCodes;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tokhub/logger.dart';
import 'package:tokhub/models/github.dart';
import 'package:tokhub/objectbox.g.dart';
import 'package:tokhub/providers/github.dart';
import 'package:tokhub/providers/objectbox.dart';
import 'package:tokhub/providers/repository.dart';

part 'pull_request.g.dart';

const _logger = Logger(['PullRequestProvider']);

@riverpod
Future<MinimalPullRequest> pullRequest(
    Ref ref, MinimalRepository repo, int number) async {
  final store = await ref.watch(objectBoxProvider.future);
  final box = store.box<MinimalPullRequest>();
  final fetched = box
      .query(MinimalPullRequest_.repo.equals(repo.id))
      .build()
      .find()
      .where((pr) => pr.number == number && pr.mergeableState != '')
      .toList(growable: false);
  if (fetched.isNotEmpty) {
    _logger.v('Found stored pull request for ${repo.slug()}#$number '
        '(${fetched.first.mergeableState})');
    return fetched.first;
  }
  return box.get(
      await ref.watch(_fetchAndStorePullRequestProvider(repo, number).future))!;
}

Future<void> pullRequestRefresh(
  WidgetRef ref,
  MinimalRepository repo,
  MinimalPullRequest pullRequest,
) async {
  ref.invalidate(_fetchAndStorePullRequestProvider(repo, pullRequest.number));
  await ref.watch(
      _fetchAndStorePullRequestProvider(repo, pullRequest.number).future);
  ref.invalidate(pullRequestProvider(repo, pullRequest.number));
}

@riverpod
Future<List<MinimalPullRequest>> pullRequests(
    Ref ref, MinimalRepository repo) async {
  final store = await ref.watch(objectBoxProvider.future);
  final box = store.box<MinimalPullRequest>();
  final fetched =
      box.query(MinimalPullRequest_.repo.equals(repo.id)).build().find();
  if (fetched.isNotEmpty) {
    _logger.v('Found ${fetched.length} '
        'stored pull requests for ${repo.slug()}');
    return fetched;
  }

  final ids = await ref.watch(_fetchAndStorePullRequestsProvider(repo).future);
  return box
      .getMany(ids)
      .whereType<MinimalPullRequest>()
      .toList(growable: false);
}

Future<void> pullRequestsRefresh(WidgetRef ref, MinimalRepository repo) async {
  ref.invalidate(_fetchAndStorePullRequestsProvider(repo));
  await ref.watch(_fetchAndStorePullRequestsProvider(repo).future);
  ref.invalidate(pullRequestsProvider(repo));
  ref.invalidate(repositoriesProvider(org: repo.owner));
}

@riverpod
Future<int> _fetchAndStorePullRequest(
    Ref ref, MinimalRepository repo, int number) async {
  final store = await ref.watch(objectBoxProvider.future);
  final box = store.box<MinimalPullRequest>();

  final pr = await ref.watch(_githubPullRequestProvider(repo, number).future);
  final id = box.put(pr..repo.target = repo);
  _logger.d('Stored pull request: ${repo.slug()}#$number (${pr.head.sha})');

  return id;
}

@riverpod
Future<List<int>> _fetchAndStorePullRequests(
    Ref ref, MinimalRepository repo) async {
  final store = await ref.watch(objectBoxProvider.future);
  final box = store.box<MinimalPullRequest>();

  // Fetch new pull requests.
  final prs = await ref.watch(_githubPullRequestsProvider(repo).future);

  // Delete old pull requests.
  box.query(MinimalPullRequest_.repo.equals(repo.id)).build().remove();

  final repoBox = store.box<MinimalRepository>();
  final userBox = store.box<MinimalUser>();
  for (final pr in prs) {
    if (repoBox.get(pr.repo.target!.id) == null) {
      repoBox.put(pr.repo.target!);
    } else {
      pr.repo.attach(store);
    }
    if (userBox.get(pr.user.target!.id) == null) {
      userBox.put(pr.user.target!);
    } else {
      pr.user.attach(store);
    }
  }

  // Store new pull requests.
  final ids = box.putMany(prs);

  for (final pr in prs) {
    if (pr.repo.targetId != pr.repo.target!.id) {
      _logger.e('Pull request ID ${pr.repo.target!.id} does not match '
          'target ID ${pr.repo.targetId}');
      continue;
    }
    if (pr.repo.target!.id != repo.id) {
      _logger.e('Pull request ${pr.repo.target!.slug()}#${pr.number} '
          'does not belong to ${repo.slug()}');
      continue;
    }
    pr.repo.target!.pullRequests.add(pr);
    repoBox.put(pr.repo.target!);
  }

  _logger.d('Stored pull requests: ${ids.length} for ${repo.slug()}');

  return ids;
}

@riverpod
Future<MinimalPullRequest> _githubPullRequest(
    Ref ref, MinimalRepository repo, int number) async {
  final slug = repo.slug();
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
    Ref ref, MinimalRepository repo) async {
  final slug = repo.slug();
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
