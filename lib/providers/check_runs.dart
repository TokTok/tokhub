import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:github/github.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tokhub/logger.dart';
import 'package:tokhub/models/github.dart';
import 'package:tokhub/objectbox.g.dart';
import 'package:tokhub/providers/github.dart';
import 'package:tokhub/providers/objectbox.dart';

part 'check_runs.g.dart';

const _logger = Logger(['CheckRunsProvider']);

const _previewHeader = 'application/vnd.github.antiope-preview+json';

@riverpod
Future<List<StoredCheckRun>> checkRuns(
  Ref ref,
  StoredRepository repo,
  StoredPullRequest pullRequest, {
  bool force = false,
}) async {
  final slug = repo.data.slug();
  final commitSha = pullRequest.data.head.sha;

  final store = await ref.watch(objectBoxProvider.future);
  final box = store.box<StoredCheckRun>();
  final fetched =
      box.query(StoredCheckRun_.sha.equals(commitSha)).build().find();
  if (fetched.isNotEmpty) {
    _logger.v('Found ${fetched.length} stored check runs for $slug@$commitSha');
    return fetched;
  }

  if (!force &&
      pullRequest.data.updatedAt!
          .isBefore(DateTime.now().subtract(maxPullRequestAge))) {
    _logger.v(
        'Pull request ${repo.data.name}/${pullRequest.data.head.ref} is too old'
        ', not fetching check runs');
    return const [];
  }

  final ids = await ref
      .watch(_fetchAndStoreCheckRunsProvider(repo, pullRequest).future);
  return box.getMany(ids).whereType<StoredCheckRun>().toList(growable: false);
}

Future<void> checkRunsRefresh(
    WidgetRef ref, StoredRepository repo, StoredPullRequest pullRequest) async {
  ref.invalidate(_fetchAndStoreCheckRunsProvider(repo, pullRequest));
  await ref.watch(_fetchAndStoreCheckRunsProvider(repo, pullRequest).future);
}

@riverpod
Future<List<int>> _fetchAndStoreCheckRuns(
    Ref ref, StoredRepository repo, StoredPullRequest pullRequest) async {
  final commitSha = pullRequest.data.head.sha;

  final store = await ref.watch(objectBoxProvider.future);
  final box = store.box<StoredCheckRun>();

  // Fetch new check runs.
  final runs =
      await ref.watch(_githubCheckRunsProvider(repo, pullRequest).future);

  // Delete existing check runs for the same commit.
  box.query(StoredCheckRun_.sha.equals(commitSha)).build().remove();

  // Store the new check runs.
  final ids = box.putMany(
      runs.map((run) => StoredCheckRun()..data = run).toList(growable: false));
  _logger.v('Stored check runs: ${runs.length}');

  return ids;
}

@riverpod
Future<List<MinimalCheckRun>> _githubCheckRuns(
    Ref ref, StoredRepository repo, StoredPullRequest pullRequest) async {
  final slug = repo.data.slug();
  final commitSha = pullRequest.data.head.sha;

  final client = await ref.watch(githubClientProvider.future);
  if (client == null) {
    return const [];
  }

  _logger.d('Fetching check runs for $slug@$commitSha');
  return PaginationHelper(client)
      .objects<Map<String, dynamic>, MinimalCheckRun>(
        'GET',
        'repos/$slug/commits/$commitSha/check-runs',
        MinimalCheckRun.fromJson,
        statusCode: StatusCodes.OK,
        preview: _previewHeader,
        arrayKey: 'check_runs',
      )
      .toList();
}
