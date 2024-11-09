import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tokhub/providers/github.dart';

final class RepositoriesView extends ConsumerWidget {
  const RepositoriesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(storedRepositoriesProvider).when(
          loading: () => const CircularProgressIndicator(),
          error: (error, stacktrace) => Text('Error: $error\n$stacktrace'),
          data: (repositories) => ListView.builder(
            itemCount: repositories.length,
            itemBuilder: (context, index) {
              final repository = repositories[index];
              return ListTile(
                title: Text(repository.data.name),
                subtitle: Text(repository.data.description),
                // Show number of pull requests.
                trailing:
                    ref.watch(storedPullRequestsProvider(repository)).when(
                          loading: () => const CircularProgressIndicator(),
                          error: (error, stacktrace) =>
                              Text('Error: $error $stacktrace'),
                          data: (pullRequests) =>
                              Text('${pullRequests.length} PRs'),
                        ),
              );
            },
          ),
        );
  }
}
