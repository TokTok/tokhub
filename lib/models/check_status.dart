import 'package:flutter/material.dart';

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
  unknown('unknown', 'Unknown', Icons.warning, Colors.red),
  loading('loading', 'Loading', Icons.timer, Colors.blue),
  success('success', 'Successful in', Icons.check_circle, Colors.green),
  neutral('neutral', 'Neutral after', Icons.info, Colors.grey),
  cancelled('cancelled', 'Cancelled after', Icons.cancel, Colors.grey),
  timedOut('timed_out', 'Timed out after', Icons.timer, Colors.grey),
  skipped('skipped', 'Skipped after', Icons.skip_next, Colors.grey),
  pending('pending', 'Pending', Icons.timelapse, Colors.orange),
  actionRequired(
      'action_required', 'Action required', Icons.warning, Colors.yellow),
  failure('failure', 'Failing after', Icons.error_outline, Colors.red),
  empty('empty', 'Unknown after', Icons.help, Colors.grey);

  final String string;
  final String title;
  final IconData icon;
  final Color color;

  const CheckStatusConclusion(this.string, this.title, this.icon, this.color);
}
