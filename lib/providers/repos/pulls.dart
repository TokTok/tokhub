import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:github/github.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tokhub/db/database.dart';
import 'package:tokhub/logger.dart';
import 'package:tokhub/providers/database.dart';
import 'package:tokhub/providers/github.dart';

part 'pulls.g.dart';

const _logger = Logger(['PullRequestProvider']);

@riverpod
Future<MinimalPullRequestData> pullRequest(
    Ref ref, RepositorySlug slug, int number,
    {bool recursed = false}) async {
  final db = await ref.watch(databaseProvider.future);
  final fetched = await (db.select(db.minimalPullRequest)
        ..where((pr) {
          return pr.repoSlug.equals(slug.fullName) & pr.number.equals(number);
        }))
      .getSingle();
  if (fetched.mergeableState == null) {
    if (recursed) {
      _logger
          .e('GitHub: pull request $slug#$number is missing mergeable state');
      return fetched;
    }
    await ref.watch(_fetchAndStorePullRequestProvider(slug, number).future);
    return pullRequest(ref, slug, number, recursed: true);
  }
  _logger.v(
      'Found stored pull request for $slug#$number (${fetched.mergeableState})');
  return fetched;
}

Future<void> pullRequestRefresh(
  WidgetRef ref,
  RepositorySlug slug,
  int number,
) async {
  ref.invalidate(_fetchAndStorePullRequestProvider(slug, number));
  await ref.watch(_fetchAndStorePullRequestProvider(slug, number).future);
  ref.invalidate(pullRequestProvider(slug, number));
}

@riverpod
Future<List<MinimalPullRequestData>> pullRequests(
    Ref ref, RepositorySlug slug) async {
  final db = await ref.watch(databaseProvider.future);

  final fetched = (await (db.select(db.minimalPullRequest)
            ..orderBy([(pr) => OrderingTerm.desc(pr.number)]))
          .get())
      .where((pr) {
    return pr.base.repo.fullName == slug.fullName;
  }).toList();

  _logger.v('Found ${fetched.length} stored pull requests for $slug');
  return fetched;
}

Future<List<MinimalPullRequestData>> pullRequestsRefresh(
    WidgetRef ref, RepositorySlug slug) async {
  ref.invalidate(_fetchAndStorePullRequestsProvider(slug));
  await ref.read(_fetchAndStorePullRequestsProvider(slug).future);
  return ref.refresh(pullRequestsProvider(slug).future);
}

@riverpod
Future<void> _fetchAndStorePullRequest(
    Ref ref, RepositorySlug slug, int number) async {
  final db = await ref.watch(databaseProvider.future);

  final pr = await ref.watch(_githubPullRequestProvider(slug, number).future);
  await db.into(db.minimalPullRequest).insertOnConflictUpdate(pr);

  final storedPr = await (db.select(db.minimalPullRequest)
        ..where((pr) {
          return pr.repoSlug.equals(slug.fullName) & pr.number.equals(number);
        }))
      .getSingle();
  _logger.v('Stored pull request: $slug#$number (${storedPr.head.sha})');
}

@riverpod
Future<void> _fetchAndStorePullRequests(Ref ref, RepositorySlug slug) async {
  final db = await ref.watch(databaseProvider.future);
  final prs = await ref.watch(_githubPullRequestsProvider(slug).future);

  await db.batch((b) {
    b.insertAllOnConflictUpdate(db.minimalPullRequest, prs);
  });

  _logger.v('Stored ${prs.length} pull requests for $slug');
}

@riverpod
Future<MinimalPullRequestData> _githubPullRequest(
    Ref ref, RepositorySlug slug, int number) async {
  final client = await ref.watch(githubClientProvider.future);
  if (client == null) {
    throw StateError('No client available');
  }

  _logger.d('Fetching pull request $slug#$number');
  return client.getJSON(
    '/repos/$slug/pulls/$number',
    convert: _logger.catching(MinimalPullRequestData.fromJson),
    statusCode: StatusCodes.OK,
  );
}

@riverpod
Future<List<MinimalPullRequestData>> _githubPullRequests(
    Ref ref, RepositorySlug slug) async {
  final client = await ref.watch(githubClientProvider.future);
  if (client == null) {
    _logger.e('GitHub: no client available');
    return const [];
  }

  _logger.v('GitHub: fetching pull requests for $slug');
  final prs = await PaginationHelper(client)
      .objects<Map<String, dynamic>, MinimalPullRequestData>(
        'GET',
        'repos/$slug/pulls',
        _logger.catching(MinimalPullRequestData.fromJson),
        statusCode: StatusCodes.OK,
      )
      .map((cr) => cr.copyWith(repoSlug: Value(slug.fullName)))
      .toList();
  _logger.d('GitHub: fetched ${prs.length} pull requests for $slug');
  return prs;
}
