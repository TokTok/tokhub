import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tokhub/db/database.dart';
import 'package:tokhub/models/github.dart';
import 'package:tokhub/providers/orgs/repos.dart';
import 'package:tokhub/providers/repos/pulls.dart';

final class RepositoriesView extends ConsumerWidget {
  final String org;

  const RepositoriesView({super.key, required this.org});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(repositoriesProvider(org)).when(
        loading: () => const CircularProgressIndicator(),
        error: (error, stacktrace) => Text('Error: $error\n$stacktrace'),
        data: (data) => _build(data, ref));
  }

  Widget _build(List<MinimalRepositoryData> repos, WidgetRef ref) {
    return ListView.builder(
      itemCount: repos.length,
      itemBuilder: (context, index) {
        final repository = repos[index];
        return ListTile(
          title: Text(repository.name),
          subtitle: Text(repository.fullName),
          trailing: FutureBuilder(
            future: ref.watch(pullRequestsProvider(repository.slug()).future),
            builder: (context, snapshot) {
              final prs = snapshot.data ?? const [];
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              return Text('PRs: ${prs.length}');
            },
          ),
        );
      },
    );
  }
}
