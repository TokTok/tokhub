import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tokhub/models/check_status.dart';
import 'package:tokhub/models/github.dart';
import 'package:tokhub/models/pull_request_info.dart';
import 'package:tokhub/providers/check_status.dart';
import 'package:url_launcher/url_launcher.dart';

final class PullRequestTile extends ConsumerWidget {
  final Map<int, TableColumnWidth> columnWidths;
  final PullRequestInfo pullRequest;

  const PullRequestTile({
    super.key,
    required this.pullRequest,
    required this.columnWidths,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textStyle = pullRequest.draft ? TextStyle(color: Colors.grey) : null;
    final checks = ref.watch(checkStatusProvider(
      pullRequest.repo.slug(),
      pullRequest.pr.head.sha,
    ));
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      dense: true,
      showTrailingIcon: false,
      title: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: columnWidths,
        children: [
          TableRow(children: [
            TextButton(
              style: ButtonStyle(
                padding: WidgetStateProperty.all(EdgeInsets.zero),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () => launchUrl(pullRequest.url),
              child: Text(pullRequest.number.toString()),
            ),
            Tooltip(
              message: pullRequest.user,
              triggerMode: TooltipTriggerMode.tap,
              child: CircleAvatar(
                backgroundImage: NetworkImage(pullRequest.avatar),
                radius: 12,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(pullRequest.branch, style: textStyle),
            ),
            Text(pullRequest.title, style: textStyle),
            Tooltip(
              message: pullRequest.state.name,
              triggerMode: TooltipTriggerMode.tap,
              child: Text(pullRequest.state.emoji),
            ),
            _statusTooltip(checks),
          ]),
        ],
      ),
      children: [
        checks.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, stacktrace) => Text('Error: $error\n$stacktrace'),
          data: (status) => Padding(
            padding: const EdgeInsets.only(right: 28.0),
            child: _buildCheckStatus(context, ref, status),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckStatus(
      BuildContext context, WidgetRef ref, List<CheckStatus> checks) {
    const outerColumnWidths = {
      1: FixedColumnWidth(32),
    };
    final refreshButton = IconButton(
      onPressed: () async {
        await checkStatusRefresh(
          ref,
          pullRequest.repo.slug(),
          pullRequest.pr.number,
        );
      },
      icon: const Icon(Icons.refresh),
    );
    if (checks.isEmpty) {
      return Table(
        columnWidths: outerColumnWidths,
        children: [
          TableRow(children: [
            Text(
              'No checks found',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            refreshButton,
          ]),
        ],
      );
    }
    // Sort by conclusion to show errors first, then by name.
    checks.sort((a, b) {
      final comparison = b.conclusion.index.compareTo(a.conclusion.index);
      return comparison == 0 ? a.name.compareTo(b.name) : comparison;
    });
    return Table(
      columnWidths: outerColumnWidths,
      children: [
        TableRow(
          children: [
            Table(
              columnWidths: {
                0: FixedColumnWidth(36),
                1: FlexColumnWidth(0.7),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                for (final check in checks)
                  TableRow(
                    children: [
                      Tooltip(
                        message: check.conclusion.name,
                        triggerMode: TooltipTriggerMode.tap,
                        child: Icon(
                          check.conclusion.icon,
                          color: check.conclusion.color,
                        ),
                      ),
                      TextButton(
                        onPressed: check.detailsUrl == null
                            ? null
                            : () => launchUrl(check.detailsUrl!),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(check.name),
                        ),
                      ),
                      Text(check.description),
                    ],
                  ),
              ],
            ),
            refreshButton,
          ],
        ),
      ],
    );
  }

  Widget _statusTooltip(AsyncValue<List<CheckStatus>> checks) {
    final status = checks.when(
      data: (statuses) => statuses.map((e) => e.conclusion).fold(
          CheckStatusConclusion.unknown,
          (value, element) => value.index >= element.index ? value : element),
      loading: () => CheckStatusConclusion.loading,
      error: (error, stacktrace) => CheckStatusConclusion.actionRequired,
    );
    return Tooltip(
      message: status.name,
      triggerMode: TooltipTriggerMode.tap,
      child: Icon(
        status.icon,
        color: status.color,
      ),
    );
  }
}
