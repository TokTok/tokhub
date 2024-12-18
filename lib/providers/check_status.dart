import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tokhub/logger.dart';
import 'package:tokhub/models/check_status.dart';
import 'package:tokhub/models/github.dart';
import 'package:tokhub/providers/check_runs.dart';
import 'package:tokhub/providers/combined_repository_status.dart';
import 'package:tokhub/providers/pull_request.dart';

part 'check_status.g.dart';

const _logger = Logger(['CheckStatusProvider']);

@riverpod
Future<List<CheckStatus>> checkStatus(
  Ref ref,
  MinimalRepository repo,
  MinimalPullRequest pullRequest, {
  required bool force,
}) async {
  final statuses = (await ref.watch(combinedRepositoryStatusProvider(
    repo,
    pullRequest,
    force: force,
  ).future))
      .statuses;
  final runs = await ref.watch(checkRunsProvider(
    repo,
    pullRequest,
    force: force,
  ).future);

  final byName = <String, CheckStatus>{};
  for (final run in runs) {
    byName[run.name] = CheckStatus(
      name: run.name,
      conclusion: run.conclusion,
      description: _completedDescription(
        run.conclusion,
        run.startedAt,
        run.completedAt,
      ),
      detailsUrl: Uri.parse(run.detailsUrl),
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

Future<void> checkStatusRefresh(WidgetRef ref, MinimalRepository repo,
    MinimalPullRequest pullRequest) async {
  await pullRequestRefresh(ref, repo, pullRequest);
  final newPr =
      await ref.watch(pullRequestProvider(repo, pullRequest.number).future);
  _logger.v(
      'Refreshing check status for ${repo.slug()}#${newPr.number} (${newPr.head.sha})');
  await combinedRepositoryStatusRefresh(ref, repo, newPr.head.sha);
  await checkRunsRefresh(ref, repo, newPr.head.sha);
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
      _logger.w('Unknown status: $state');
      return CheckStatusConclusion.empty;
  }
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
