import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tokhub/db/database.dart';
import 'package:tokhub/logger.dart';
import 'package:tokhub/models/github.dart';
import 'package:tokhub/providers/orgs/repos.dart';
import 'package:tokhub/providers/repos/issues.dart';

part 'issues_view.g.dart';

const _logger = Logger(['IssuesView']);

@riverpod
Future<List<(MinimalRepositoryData, List<MinimalIssueData>)>> reposWithIssues(
    Ref ref, String org,
    {bool includeEmpty = false}) async {
  final repos = await ref.watch(repositoriesProvider(org).future);
  final pairs = await Future.wait(repos.map((repo) async {
    final issues = await ref.watch(issuesProvider(repo.slug()).future);
    return (repo, issues);
  }));

  if (includeEmpty) {
    return pairs;
  }
  return pairs.where((pair) => pair.$2.isNotEmpty).toList(growable: false);
}

final class IssuesView extends ConsumerWidget {
  final String org;

  const IssuesView({super.key, required this.org});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(reposWithIssuesProvider(org)).when(
        skipLoadingOnReload: true,
        loading: () => const CircularProgressIndicator(),
        error: (error, stacktrace) => Text('Error: $error\n$stacktrace'),
        data: (data) => _build(data, ref));
  }

  Widget _build(List<(MinimalRepositoryData, List<MinimalIssueData>)> repos,
      WidgetRef ref) {
    return ListView.builder(
      itemCount: repos.length,
      itemBuilder: (context, index) {
        final (repo, issues) = repos[index];
        return ExpansionTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text('${repo.name} (${issues.length})'),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  _logger.v('Refreshing issues for ${repo.slug()}');
                  await issuesRefresh(ref, repo.slug());
                },
              ),
            ],
          ),
          children: [
            for (final issue in issues)
              ExpansionTile(
                title: Text('#${issue.number} ${issue.title}'),
                children: [
                  if (issue.body != null) MarkdownBody(data: issue.body!),
                ],
              ),
          ],
        );
      },
    );
  }
}
