import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tokhub/providers/github.dart';

final class RepositoriesView extends ConsumerWidget {
  const RepositoriesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(repositoriesProvider).when(
          loading: () => const CircularProgressIndicator(),
          error: (error, _) => Text('Error: $error'),
          data: (repositories) => ListView.builder(
            itemCount: repositories.length,
            itemBuilder: (context, index) {
              final repository = repositories[index];
              return ListTile(
                title: Text(repository.name),
                subtitle: Text(repository.description),
                // Show number of pull requests.
                trailing:
                    ref.watch(pullRequestsProvider(repository.slug())).when(
                          loading: () => const CircularProgressIndicator(),
                          error: (error, _) => Text('Error: $error'),
                          data: (pullRequests) =>
                              Text('${pullRequests.length} PRs'),
                        ),
              );
            },
          ),
        );
  }
}
