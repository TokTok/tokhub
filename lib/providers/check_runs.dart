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
Future<List<MinimalCheckRun>> checkRuns(
  Ref ref,
  MinimalRepository repo,
  MinimalPullRequest pullRequest, {
  required bool force,
}) async {
  final slug = repo.slug();
  final commitSha = pullRequest.head.sha;

  final store = await ref.watch(objectBoxProvider.future);
  final box = store.box<MinimalCheckRun>();
  final fetched =
      box.query(MinimalCheckRun_.headSha.equals(commitSha)).build().find();
  if (fetched.isNotEmpty) {
    _logger.v('Found ${fetched.length} stored check runs for $slug@$commitSha');
    return fetched;
  }

  if (!force &&
      pullRequest.updatedAt!
          .isBefore(DateTime.now().subtract(maxPullRequestAge))) {
    _logger.v('Pull request ${slug.name}/${pullRequest.head.ref} is too old'
        ', not fetching check runs');
    return const [];
  }

  final ids = await ref
      .watch(_fetchAndStoreCheckRunsProvider(repo, commitSha).future);
  return box.getMany(ids).whereType<MinimalCheckRun>().toList(growable: false);
}

Future<void> checkRunsRefresh(WidgetRef ref, MinimalRepository repo,
    String commitSha) async {
  ref.invalidate(_fetchAndStoreCheckRunsProvider(repo, commitSha));
  await ref.watch(_fetchAndStoreCheckRunsProvider(repo, commitSha).future);
}

@riverpod
Future<List<int>> _fetchAndStoreCheckRuns(
    Ref ref, MinimalRepository repo, String commitSha) async {
  final slug = repo.slug();
  final store = await ref.watch(objectBoxProvider.future);
  final box = store.box<MinimalCheckRun>();

  // Fetch new check runs.
  final runs =
      await ref.watch(_githubCheckRunsProvider(slug, commitSha).future);

  // Delete existing check runs for the same commit.
  box.query(MinimalCheckRun_.headSha.equals(commitSha)).build().remove();

  // Store the new check runs.
  final ids = box.putMany(runs);
  _logger.v('Stored check runs: ${runs.length}');

  return ids;
}

@riverpod
Future<List<MinimalCheckRun>> _githubCheckRuns(
    Ref ref, RepositorySlug slug, String commitSha) async {
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
