import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tokhub/models/github.dart';
import 'package:tokhub/models/pull_request_info.dart';
import 'package:tokhub/providers/pull_request_info.dart';

final class RepositoriesView extends ConsumerWidget {
  final String org;

  const RepositoriesView({super.key, required this.org});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(pullRequestInfosProvider(org: org)).when(
        loading: () => const CircularProgressIndicator(),
        error: (error, stacktrace) => Text('Error: $error\n$stacktrace'),
        data: (data) => _build(data, ref));
  }

  Widget _build(List<(MinimalRepository, List<PullRequestInfo>)> repositories,
      WidgetRef ref) {
    return ListView.builder(
      itemCount: repositories.length,
      itemBuilder: (context, index) {
        final (repo, prs) = repositories[index];
        return ListTile(
          title: Text(repo.name),
          subtitle: Text(repo.description ?? ''),
          // Show number of pull requests.
          trailing: Text('${prs.length} PRs'),
        );
      },
    );
  }
}
