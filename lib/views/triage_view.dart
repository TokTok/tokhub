import 'package:drift/drift.dart' hide Column, Table;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tokhub/db/database.dart';
import 'package:tokhub/models/github.dart';
import 'package:tokhub/providers/database.dart';
import 'package:tokhub/providers/notifications.dart';
import 'package:url_launcher/url_launcher.dart';

part 'triage_view.g.dart';

@riverpod
Future<_TriageData> _triageData(Ref ref) async {
  final db = await ref.watch(databaseProvider.future);
  final issues = await (db.select(db.minimalIssue)
        ..where((issue) => issue.milestone.isNull())
        ..orderBy([
          (issue) => OrderingTerm(expression: issue.repoSlug),
          (issue) => OrderingTerm(expression: issue.number),
        ]))
      .get();

  final notifications = await ref.watch(notificationsProvider.future);

  return _TriageData(issues, notifications);
}

final class TriageView extends ConsumerWidget {
  const TriageView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(_triageDataProvider).when(
        loading: () => const LinearProgressIndicator(),
        error: (error, stacktrace) => Text('Error: $error\n$stacktrace'),
        data: (data) => _build(context, data, ref));
  }

  Widget _build(BuildContext context, _TriageData data, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(children: [
        Text('Notifications:', style: Theme.of(context).textTheme.titleLarge),
        if (data.notifications.isEmpty)
          const Center(child: Text('No notifications to triage! 🎉'))
        else
          Table(
            columnWidths: const {
              0: FixedColumnWidth(24),
              1: FlexColumnWidth(),
              2: FixedColumnWidth(48),
            },
            children: [
              for (final notification in data.notifications)
                TableRow(
                  children: [
                    Center(child: Text(notification.subject.type.emoji)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notification.repository.fullName,
                              style: Theme.of(context).textTheme.bodySmall),
                          TextButton(
                            onPressed: _launchNotificationUrl(notification),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(notification.subject.title),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Mark as done
                    IconButton(
                      icon: const Icon(Icons.done),
                      onPressed: () async {
                        await notificationsMarkDone(ref, notification.id);
                      },
                    ),
                  ],
                ),
            ],
          ),
        const Divider(),
        Text('Triage list:', style: Theme.of(context).textTheme.titleLarge),
        if (data.issues.isEmpty)
          const Center(child: Text('No issues to triage! 🎉'))
        else
          ListView.builder(
            shrinkWrap: true,
            itemCount: data.issues.length,
            itemBuilder: (context, index) {
              final issue = data.issues[index];
              return ListTile(
                title: TextButton(
                  onPressed: () => launchUrl(Uri.parse(issue.htmlUrl)),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${issue.repoSlug}#${issue.number}'),
                  ),
                ),
                subtitle: Text(issue.title),
              );
            },
          )
      ]),
    );
  }
}

final class _TriageData {
  final List<MinimalIssueData> issues;
  final List<MinimalNotificationData> notifications;

  _TriageData(this.issues, this.notifications);
}

void Function()? _launchNotificationUrl(MinimalNotificationData notification) {
  // "url": "https://api.github.com/repos/TokTok/qTox/issues/170",
  final Uri? issueUri = notification.subject.url;
  // "latest_comment_url": "https://api.github.com/repos/TokTok/qTox/issues/comments/2608006607"
  final Uri? commentUri = notification.subject.latestCommentUrl;

  if (issueUri == null) {
    return null;
  }

  final String repo = notification.repository.fullName;
  final String type = notification.subject.type.path;

  if (commentUri != null) {
    final Uri url = Uri(
      scheme: 'https',
      host: 'github.com',
      path: '$repo/$type/${issueUri.pathSegments.last}',
      fragment: 'issuecomment-${commentUri.pathSegments.last}',
    );
    return () => launchUrl(url);
  }

  final Uri url = Uri(
    scheme: 'https',
    host: 'github.com',
    path: '$repo/$type/${issueUri.pathSegments.last}',
  );
  return () => launchUrl(url);
}
