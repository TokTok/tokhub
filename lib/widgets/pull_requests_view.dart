import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tokhub/db/database.dart';
import 'package:tokhub/logger.dart';
import 'package:tokhub/models/github.dart';
import 'package:tokhub/models/pull_request_info.dart';
import 'package:tokhub/providers/orgs/repos.dart';
import 'package:tokhub/providers/repos/pulls.dart';
import 'package:tokhub/widgets/pull_request_tile.dart';

part 'pull_requests_view.g.dart';

const _logger = Logger(['PullRequestsView']);

@riverpod
Future<List<(MinimalRepositoryData, List<MinimalPullRequestData>)>>
    reposWithPulls(Ref ref, String org, {bool includeEmpty = false}) async {
  final repos = await ref.watch(repositoriesProvider(org).future);
  final pairs = await Future.wait(repos.map((repo) async {
    final prs = await ref.watch(pullRequestsProvider(repo.slug()).future);
    return (repo, prs);
  }));
  if (includeEmpty) {
    return pairs;
  }
  return pairs.where((pair) => pair.$2.isNotEmpty).toList(growable: false);
}

final class PullRequestsView extends ConsumerWidget {
  final String org;

  const PullRequestsView({super.key, required this.org});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(reposWithPullsProvider(org)).when(
        loading: () => const CircularProgressIndicator(),
        error: (error, stacktrace) => Text('Error: $error\n$stacktrace'),
        data: (data) => _build(data, ref));
  }

  Widget _build(
      List<(MinimalRepositoryData, List<MinimalPullRequestData>)> repos,
      WidgetRef ref) {
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
            itemCount: repos.length,
            itemBuilder: (context, index) {
              final (repo, prs) = repos[index];
              return ExpansionTile(
                enabled: prs.isNotEmpty,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text('${repo.name} (${prs.length})'),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () async {
                        _logger
                            .v('Refreshing pull requests for ${repo.slug()}');
                        await pullRequestsRefresh(ref, repo.slug());
                      },
                    ),
                  ],
                ),
                children: [
                  for (final pr in prs)
                    ref.watch(pullRequestProvider(repo.slug(), pr.number)).when(
                          loading: () => PullRequestTile(
                            pullRequest: PullRequestInfo.from(repo, pr),
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
              );
            },
          ),
        ),
      ],
    );
  }
}
