import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:github/github.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tokhub/db/database.dart';
import 'package:tokhub/logger.dart';
import 'package:tokhub/providers/database.dart';
import 'package:tokhub/providers/github.dart';

part 'issues.g.dart';

const _logger = Logger(['IssuesProvider']);

@riverpod
Future<List<MinimalIssueData>> issues(Ref ref, RepositorySlug slug) async {
  final db = await ref.watch(databaseProvider.future);

  final fetched = await (db.select(db.minimalIssue)
        ..where(
            (pr) => pr.repoSlug.equals(slug.fullName) & pr.pullRequest.isNull())
        ..orderBy([(pr) => OrderingTerm.desc(pr.number)]))
      .get();

  _logger.v('Found ${fetched.length} stored issues for $slug');
  return fetched;
}

Future<List<MinimalIssueData>> issuesRefresh(
    WidgetRef ref, RepositorySlug slug) async {
  ref.invalidate(_fetchAndStoreIssuesProvider(slug));
  await ref.read(_fetchAndStoreIssuesProvider(slug).future);
  return ref.refresh(issuesProvider(slug).future);
}

@riverpod
Future<void> _fetchAndStoreIssues(Ref ref, RepositorySlug slug) async {
  final db = await ref.watch(databaseProvider.future);
  final issues = await ref.watch(_githubIssuesProvider(slug).future);

  await db.batch((b) {
    b.insertAllOnConflictUpdate(db.minimalIssue, issues);
  });

  _logger.v('Stored ${issues.length} issues for $slug');
}

@riverpod
Future<List<MinimalIssueData>> _githubIssues(
    Ref ref, RepositorySlug slug) async {
  final client = await ref.watch(githubClientProvider.future);
  if (client == null) {
    _logger.e('GitHub: no client available');
    return const [];
  }

  _logger.v('GitHub: fetching issues for $slug');
  final issues = await PaginationHelper(client)
      .objects<Map<String, dynamic>, MinimalIssueData>(
        'GET',
        'repos/$slug/issues',
        _logger.catching(MinimalIssueData.fromJson),
        statusCode: StatusCodes.OK,
      )
      .map((cr) => cr.copyWith(repoSlug: Value(slug.fullName)))
      .toList();
  _logger.d('GitHub: fetched ${issues.length} issues for $slug');
  return issues;
}
