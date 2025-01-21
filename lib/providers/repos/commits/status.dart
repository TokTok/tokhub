import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:github/github.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tokhub/db/database.dart';
import 'package:tokhub/logger.dart';
import 'package:tokhub/providers/database.dart';
import 'package:tokhub/providers/github.dart';

part 'status.g.dart';

const _logger = Logger(['CombinedRepositoryStatusProvider']);

@riverpod
Future<List<MinimalCommitStatusData>> combinedRepositoryStatus(
    Ref ref, RepositorySlug slug, String headSha) async {
  final db = await ref.watch(databaseProvider.future);
  final fetched = await (db.select(db.minimalCommitStatus)
        ..where((status) {
          return status.repoSlug.equals(slug.fullName) &
              status.headSha.equals(headSha);
        }))
      .get();
  _logger.v('Found stored combined repository status for $slug@$headSha '
      '(${fetched.length} statuses)');
  return fetched;
}

Future<void> combinedRepositoryStatusRefresh(
    WidgetRef ref, RepositorySlug slug, String commitSha) async {
  ref.invalidate(
      _fetchAndStoreCombinedRepositoryStatusProvider(slug, commitSha));
  await ref.watch(
      _fetchAndStoreCombinedRepositoryStatusProvider(slug, commitSha).future);
}

@riverpod
Future<void> _fetchAndStoreCombinedRepositoryStatus(
    Ref ref, RepositorySlug slug, String commitSha) async {
  // Fetch the combined status from GitHub.
  final statuses = await ref
      .watch(_githubCombinedRepositoryStatusProvider(slug, commitSha).future);

  final db = await ref.watch(databaseProvider.future);

  // Store the new statuses.
  for (final status in statuses) {
    await db.into(db.minimalCommitStatus).insertOnConflictUpdate(status);
  }
}

@riverpod
Future<List<MinimalCommitStatusData>> _githubCombinedRepositoryStatus(
    Ref ref, RepositorySlug slug, String commitSha) async {
  final client = await ref.watch(githubClientProvider.future);
  if (client == null) {
    throw StateError('No client available');
  }

  _logger.d('Fetching commit status for $slug@$commitSha');
  final statuses =
      client.getJSON<Map<String, dynamic>, List<MinimalCommitStatusData>>(
    '/repos/$slug/commits/$commitSha/status',
    convert: (crs) => (crs['statuses'] as List<dynamic>)
        .map((json) => _logger
            .catching(MinimalCommitStatusData.fromJson)(json)
            .copyWith(
                repoSlug: Value(slug.fullName), headSha: Value(commitSha)))
        .toList(),
    statusCode: StatusCodes.OK,
  );

  return statuses;
}
