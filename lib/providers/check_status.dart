import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tokhub/models/github.dart';
import 'package:tokhub/providers/check_runs.dart';
import 'package:tokhub/providers/combined_repository_status.dart';

part 'check_status.g.dart';

Future<void> checkStatusRefresh(
    WidgetRef ref, StoredRepository repo, StoredPullRequest pullRequest) async {
  combinedRepositoryStatusRefresh(ref, repo, pullRequest);
  checkRunsRefresh(ref, repo, pullRequest);
}

@riverpod
Future<List<CheckStatus>> checkStatus(
  Ref ref,
  StoredRepository repo,
  StoredPullRequest pullRequest, {
  required bool force,
}) async {
  final statuses = (await ref.watch(combinedRepositoryStatusProvider(
    repo,
    pullRequest,
    force: force,
  ).future))
      .data
      .statuses;
  final runs = await ref.watch(checkRunsProvider(
    repo,
    pullRequest,
    force: force,
  ).future);

  final byName = <String, CheckStatus>{};
  for (final run in runs) {
    byName[run.data.name] = CheckStatus(
      name: run.data.name,
      conclusion: run.data.conclusion,
      description: _completedDescription(
        run.data.conclusion,
        run.data.startedAt,
        run.data.completedAt,
      ),
      detailsUrl: Uri.parse(run.data.detailsUrl),
    );
  }
  if (statuses != null) {
    for (final status in statuses) {
      byName[status.context!] = CheckStatus(
        name: status.context!,
        conclusion: _statusConclusion(status.state),
        description: '${_capitalize(status.state)} — ${status.description}',
        detailsUrl:
            status.targetUrl == null ? null : Uri.parse(status.targetUrl!),
      );
    }
  }

  return byName.values.toList(growable: false);
}

String _capitalize(String? string) {
  if (string == null || string.isEmpty) {
    return '';
  }
  return string[0].toUpperCase() + string.substring(1);
}

String _completedDescription(
  CheckStatusConclusion conclusion,
  DateTime? startedAt,
  DateTime? completedAt,
) {
  if (startedAt == null || completedAt == null) {
    return '';
  }
  final duration = completedAt.difference(startedAt);
  return '${conclusion.title} ${_timeDescription(duration)}';
}

String _timeDescription(Duration duration) {
  final parts = <String>[];
  if (duration.inHours > 0) {
    parts.add('${duration.inHours}h');
  }
  if (duration.inMinutes > 0) {
    parts.add('${duration.inMinutes.remainder(60)}m');
  }
  parts.add('${duration.inSeconds.remainder(60)}s');
  return parts.join(' ');
}

CheckStatusConclusion _statusConclusion(String? state) {
  switch (state) {
    case 'success':
      return CheckStatusConclusion.success;
    case 'failure':
      return CheckStatusConclusion.failure;
    case 'error':
      return CheckStatusConclusion.failure;
    case 'pending':
      return CheckStatusConclusion.pending;
    default:
      return CheckStatusConclusion.empty;
  }
}

final class CheckStatus {
  final String name;
  final CheckStatusConclusion conclusion;
  final String description;
  final Uri? detailsUrl;

  const CheckStatus({
    required this.name,
    required this.conclusion,
    required this.description,
    required this.detailsUrl,
  });
}

enum CheckStatusConclusion {
  empty('empty', 'Unknown after', Icons.help, Colors.grey),
  success('success', 'Successful in', Icons.check_circle, Colors.green),
  cancelled('cancelled', 'Cancelled after', Icons.cancel, Colors.grey),
  timedOut('timed_out', 'Timed out after', Icons.timer, Colors.grey),
  skipped('skipped', 'Skipped after', Icons.skip_next, Colors.grey),
  pending('pending', 'Pending', Icons.timelapse, Colors.orange),
  actionRequired(
      'action_required', 'Action required', Icons.warning, Colors.yellow),
  failure('failure', 'Failing after', Icons.error_outline, Colors.red);

  final String string;
  final String title;
  final IconData icon;
  final Color color;

  const CheckStatusConclusion(this.string, this.title, this.icon, this.color);
}
