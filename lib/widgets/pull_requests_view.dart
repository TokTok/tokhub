import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tokhub/models/github.dart';
import 'package:tokhub/models/pull_request_info.dart';
import 'package:tokhub/providers/pull_request.dart';
import 'package:tokhub/providers/repository.dart';
import 'package:tokhub/widgets/pull_request_tile.dart';

final class PullRequestsView extends ConsumerWidget {
  const PullRequestsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(repositoriesProvider).when(
        loading: () => const CircularProgressIndicator(),
        error: (error, stacktrace) => Text('Error: $error\n$stacktrace'),
        data: (data) => _build(data, ref));
  }

  Widget _build(List<StoredRepository> repositories, WidgetRef ref) {
    final reposWithPrs = repositories
        .where((repo) => repo.pullRequests.isNotEmpty)
        .toList(growable: false);
    reposWithPrs.sort((a, b) => a.data.name.compareTo(b.data.name));
    const columnWidths = {
      0: FixedColumnWidth(48),
      1: FixedColumnWidth(36),
      2: FixedColumnWidth(96),
      4: FixedColumnWidth(24),
      5: FixedColumnWidth(24),
    };
    const titleStyle = TextStyle(
      fontWeight: FontWeight.bold,
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Table(
            columnWidths: {...columnWidths, 4: FixedColumnWidth(48)},
            children: const [
              TableRow(children: [
                Text('PR', style: titleStyle),
                Text('User', style: titleStyle),
                Text('Branch', style: titleStyle),
                Text('Title', style: titleStyle),
                Text('State', style: titleStyle),
              ]),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: reposWithPrs.length,
            itemBuilder: (context, index) {
              final repo = reposWithPrs[index];
              final prs = repo.pullRequests
                  .map((spr) => PullRequestInfo.from(repo, spr))
                  .toList(growable: false);
              prs.sort((a, b) => b.number.compareTo(a.number));
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(repo.data.name),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => pullRequestsRefresh(ref, repo),
                    ),
                  ],
                ),
                subtitle: Column(
                  children: [
                    for (final pr in prs)
                      ref.watch(pullRequestProvider(repo, pr.number)).when(
                            loading: () => PullRequestTile(
                              pullRequest: pr,
                              columnWidths: columnWidths,
                            ),
                            error: (error, stacktrace) =>
                                Text('Error: $error $stacktrace'),
                            data: (spr) => PullRequestTile(
                              pullRequest: PullRequestInfo.from(repo, spr),
                              columnWidths: columnWidths,
                            ),
                          ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
