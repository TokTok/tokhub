import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:github/github.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tokhub/logger.dart';
import 'package:tokhub/models/github.dart';
import 'package:tokhub/providers/check_runs.dart';
import 'package:tokhub/providers/combined_repository_status.dart';

part 'check_status.g.dart';

const _logger = Logger(['CheckStatusProvider']);

Future<void> checkStatusRefresh(
    WidgetRef ref, StoredRepository repo, StoredPullRequest pullRequest) async {
  combinedRepositoryStatusRefresh(ref, repo, pullRequest);
  checkRunsRefresh(ref, repo, pullRequest);
}

@riverpod
Future<List<CheckStatus>> checkStatus(
    Ref ref, StoredRepository repo, StoredPullRequest pullRequest,
    {bool force = false}) async {
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
    byName[run.data!.name!] = CheckStatus(
      name: run.data!.name!,
      conclusion: _checkConclusion(run.data!.conclusion),
      // TODO(iphydf): When the github api supports completed_at, show the time
      // taken (completed - started).
      description: '',
      detailsUrl: Uri.parse(run.data!.detailsUrl!),
    );
  }
  if (statuses != null) {
    for (final status in statuses) {
      byName[status.context!] = CheckStatus(
        name: status.context!,
        conclusion: _statusConclusion(status.state),
        description: status.description!,
        detailsUrl:
            status.targetUrl == null ? null : Uri.parse(status.targetUrl!),
      );
    }
  }

  return byName.values.toList(growable: false);
}

CheckStatusConclusion _checkConclusion(CheckRunConclusion state) {
  switch (state) {
    case CheckRunConclusion.success:
      return CheckStatusConclusion.success;
    case CheckRunConclusion.failure:
      return CheckStatusConclusion.failure;
    case CheckRunConclusion.neutral:
      return CheckStatusConclusion.pending;
    case CheckRunConclusion.cancelled:
      return CheckStatusConclusion.cancelled;
    case CheckRunConclusion.timedOut:
      return CheckStatusConclusion.timedOut;
    case CheckRunConclusion.skipped:
      return CheckStatusConclusion.skipped;
    case CheckRunConclusion.actionRequired:
      return CheckStatusConclusion.actionRequired;
    default:
      return CheckStatusConclusion.empty;
  }
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
  empty(Icons.help, Colors.grey),
  success(Icons.check_circle, Colors.green),
  cancelled(Icons.cancel, Colors.grey),
  timedOut(Icons.timer, Colors.grey),
  skipped(Icons.skip_next, Colors.grey),
  pending(Icons.timelapse, Colors.orange),
  actionRequired(Icons.warning, Colors.yellow),
  failure(Icons.error_outline, Colors.red);

  final IconData icon;
  final Color color;

  const CheckStatusConclusion(this.icon, this.color);
}
