import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tokhub/models/github.dart';
import 'package:tokhub/models/pull_request_info.dart';
import 'package:tokhub/providers/github.dart';
import 'package:url_launcher/url_launcher.dart';

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
      4: FixedColumnWidth(36),
    };
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Table(
            columnWidths: columnWidths,
            children: const [
              TableRow(children: [
                Text('PR'),
                Text('User'),
                Text('Branch'),
                Text('Title'),
                Text('State'),
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
                  .map((spr) => PullRequestInfo.from(spr.data))
                  .toList(growable: false);
              prs.sort((a, b) => b.number.compareTo(a.number));
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                title: Text(repo.data.name),
                subtitle: Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: columnWidths,
                  children: [
                    for (final pr in prs)
                      TableRow(children: [
                        TextButton(
                          style: ButtonStyle(
                            padding: WidgetStateProperty.all(EdgeInsets.zero),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => launchUrl(pr.url),
                          child: Text(pr.number.toString()),
                        ),
                        Tooltip(
                          message: pr.user,
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(pr.avatar),
                            radius: 12,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(pr.branch),
                        ),
                        Text(pr.title),
                        // Text(pr.state.emoji),
                        Tooltip(
                          message: pr.state.name,
                          child: Text(pr.state.emoji),
                        ),
                      ]),
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
