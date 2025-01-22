import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tokhub/db/database.dart';
import 'package:tokhub/models/github.dart';
import 'package:tokhub/providers/orgs/repos.dart';
import 'package:tokhub/providers/repos/issues.dart';
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
    return SingleChildScrollView(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Issues')),
          DataColumn(label: Text('Pull Requests')),
        ],
        rows: [
          for (final repository in repos)
            DataRow(cells: [
              DataCell(Text(repository.name)),
              DataCell(
                ref.watch(issuesProvider(repository.slug())).when(
                      loading: () => const CircularProgressIndicator(),
                      error: (error, stacktrace) =>
                          Text('Error: $error\n$stacktrace'),
                      data: (issues) => Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.refresh),
                            onPressed: () =>
                                issuesRefresh(ref, repository.slug()),
                          ),
                          Text('${issues.length}'),
                        ],
                      ),
                    ),
              ),
              DataCell(
                ref.watch(pullRequestsProvider(repository.slug())).when(
                      loading: () => const CircularProgressIndicator(),
                      error: (error, stacktrace) =>
                          Text('Error: $error\n$stacktrace'),
                      data: (prs) => Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.refresh),
                            onPressed: () =>
                                pullRequestsRefresh(ref, repository.slug()),
                          ),
                          Text('${prs.length}'),
                        ],
                      ),
                    ),
              ),
            ]),
        ],
      ),
    );
  }
}
