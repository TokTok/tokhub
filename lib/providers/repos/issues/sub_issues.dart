import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:github/github.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tokhub/db/database.dart';
import 'package:tokhub/logger.dart';
import 'package:tokhub/providers/database.dart';
import 'package:tokhub/providers/github.dart';

part 'sub_issues.g.dart';

const _logger = Logger(['SubIssuesProvider']);

@riverpod
Future<List<MinimalIssueData>> subIssues(
    Ref ref, RepositorySlug slug, int issueNumber) async {
  final db = await ref.watch(databaseProvider.future);

  final fetched = await (db.select(db.minimalIssue)
        ..where((pr) =>
            pr.repoSlug.equals(slug.fullName) & pr.parent.equals(issueNumber))
        ..orderBy([(pr) => OrderingTerm.desc(pr.number)]))
      .get();

  _logger.v('Found ${fetched.length} stored issues for $slug#$issueNumber');
  return fetched;
}

Future<List<MinimalIssueData>> subIssuesRefresh(
    WidgetRef ref, RepositorySlug slug, int issueNumber) async {
  ref.invalidate(_fetchAndStoreSubIssuesProvider(slug, issueNumber));
  await ref.read(_fetchAndStoreSubIssuesProvider(slug, issueNumber).future);
  return ref.refresh(subIssuesProvider(slug, issueNumber).future);
}

@riverpod
Future<void> _fetchAndStoreSubIssues(
    Ref ref, RepositorySlug slug, int issueNumber) async {
  final db = await ref.watch(databaseProvider.future);
  final issues =
      await ref.watch(_githubSubIssuesProvider(slug, issueNumber).future);

  await db.batch((b) {
    b.insertAllOnConflictUpdate(db.minimalIssue, issues);
  });

  _logger.v('Stored ${issues.length} sub-issues for $slug#$issueNumber');
}

@riverpod
Future<List<MinimalIssueData>> _githubSubIssues(
    Ref ref, RepositorySlug slug, int issueNumber) async {
  final client = await ref.watch(githubClientProvider.future);
  if (client == null) {
    _logger.e('GitHub: no client available');
    return const [];
  }

  _logger.v('GitHub: fetching sub-issues for $slug');
  final prs = await PaginationHelper(client)
      .objects<Map<String, dynamic>, MinimalIssueData>(
        'GET',
        'repos/$slug/issues/$issueNumber/sub_issues',
        _logger.catching(MinimalIssueData.fromJson),
        statusCode: StatusCodes.OK,
      )
      .map((cr) => cr.copyWith(
          repoSlug: Value(slug.fullName), parent: Value(issueNumber)))
      .toList();
  _logger.d('GitHub: fetched ${prs.length} sub-issues for $slug#$issueNumber');
  return prs;
}
