import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:github/github.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tokhub/db/database.dart';
import 'package:tokhub/logger.dart';
import 'package:tokhub/providers/database.dart';
import 'package:tokhub/providers/github.dart';

part 'check_runs.g.dart';

const _logger = Logger(['CheckRunsProvider']);

const _previewHeader = 'application/vnd.github.antiope-preview+json';

@riverpod
Future<List<MinimalCheckRunData>> checkRuns(
    Ref ref, RepositorySlug slug, String headSha) async {
  final db = await ref.watch(databaseProvider.future);

  final fetched = await (db.select(db.minimalCheckRun)
        ..where((run) {
          return run.repoSlug.equals(slug.fullName) &
              run.headSha.equals(headSha);
        }))
      .get();

  return fetched;
}

Future<List<MinimalCheckRunData>> checkRunsRefresh(
    WidgetRef ref, RepositorySlug slug, String commitSha) async {
  ref.invalidate(_fetchAndStoreCheckRunsProvider(slug, commitSha));
  await ref.read(_fetchAndStoreCheckRunsProvider(slug, commitSha).future);
  return ref.refresh(checkRunsProvider(slug, commitSha).future);
}

@riverpod
Future<void> _fetchAndStoreCheckRuns(
    Ref ref, RepositorySlug slug, String commitSha) async {
  final runs =
      await ref.watch(_githubCheckRunsProvider(slug, commitSha).future);
  final db = await ref.watch(databaseProvider.future);

  await db.batch((b) {
    b.insertAllOnConflictUpdate(db.minimalCheckRun, runs);
  });
}

@riverpod
Future<List<MinimalCheckRunData>> _githubCheckRuns(
    Ref ref, RepositorySlug slug, String commitSha) async {
  final client = await ref.watch(githubClientProvider.future);
  if (client == null) {
    return const [];
  }

  _logger.d('Fetching check runs for $slug@$commitSha');
  return PaginationHelper(client)
      .objects<Map<String, dynamic>, MinimalCheckRunData>(
        'GET',
        'repos/$slug/commits/$commitSha/check-runs',
        _logger.catching(MinimalCheckRunData.fromJson),
        statusCode: StatusCodes.OK,
        preview: _previewHeader,
        arrayKey: 'check_runs',
      )
      .map((cr) => cr.copyWith(repoSlug: Value(slug.fullName)))
      .toList();
}
