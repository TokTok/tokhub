import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:github/github.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tokhub/db/database.dart';
import 'package:tokhub/logger.dart';
import 'package:tokhub/providers/database.dart';
import 'package:tokhub/providers/github.dart';

part 'status.g.dart';

const _logger = Logger(['CommitStatusProvider']);

@riverpod
Future<List<MinimalCommitStatusData>> commitStatus(
    Ref ref, RepositorySlug slug, String headSha) async {
  final db = await ref.watch(databaseProvider.future);
  final fetched = await (db.select(db.minimalCommitStatus)
        ..where((status) {
          return status.repoSlug.equals(slug.fullName) &
              status.headSha.equals(headSha);
        }))
      .get();
  _logger.v('Found stored commit status for $slug@$headSha '
      '(${fetched.length} statuses)');
  return fetched;
}

Future<List<MinimalCommitStatusData>> commitStatusRefresh(
    WidgetRef ref, RepositorySlug slug, String commitSha) async {
  ref.invalidate(_fetchAndStoreCommitStatusProvider(slug, commitSha));
  await ref.read(_fetchAndStoreCommitStatusProvider(slug, commitSha).future);
  return ref.refresh(commitStatusProvider(slug, commitSha).future);
}

@riverpod
Future<void> _fetchAndStoreCommitStatus(
    Ref ref, RepositorySlug slug, String commitSha) async {
  final statuses =
      await ref.watch(_githubCommitStatusProvider(slug, commitSha).future);
  final db = await ref.watch(databaseProvider.future);

  await db.batch((b) {
    b.insertAllOnConflictUpdate(db.minimalCommitStatus, statuses);
  });
}

@riverpod
Future<List<MinimalCommitStatusData>> _githubCommitStatus(
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
