import 'package:flutter/material.dart';
import 'package:github/github.dart';

final class RepositoriesView extends StatelessWidget {
  final List<Repository> repositories;
  final Map<RepositorySlug, List<PullRequest>> pullRequests;

  const RepositoriesView({
    super.key,
    required this.repositories,
    required this.pullRequests,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: repositories.length,
      itemBuilder: (context, index) {
        final repository = repositories[index];
        return ListTile(
          title: Text(repository.name),
          subtitle: Text(repository.description),
          // Show number of pull requests.
          trailing: Text('${pullRequests[repository.slug()]?.length ?? 0} PRs'),
        );
      },
    );
  }
}
