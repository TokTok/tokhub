import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:github/github.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tokhub/logger.dart';
import 'package:tokhub/models/github.dart';
import 'package:tokhub/providers/github.dart';

part 'notifications.g.dart';

const _logger = Logger(['NotificationsProvider']);

@riverpod
Future<List<MinimalNotificationData>> notifications(Ref ref) async {
  final client = await ref.watch(githubClientProvider.future);
  if (client == null) {
    _logger.e('GitHub: no client available');
    return const [];
  }

  _logger.v('GitHub: fetching notifications');
  final notes = await PaginationHelper(client)
      .objects<Map<String, dynamic>, MinimalNotificationData>(
        'GET',
        'notifications',
        _logger.catching(MinimalNotificationData.fromJson),
        statusCode: StatusCodes.OK,
      )
      .toList();
  _logger.d('GitHub: fetched ${notes.length} notifications');
  return notes;
}

Future<void> notificationsMarkDone(WidgetRef ref, int threadId) async {
  final client = await ref.watch(githubClientProvider.future);
  if (client == null) {
    _logger.e('GitHub: no client available');
    return;
  }

  _logger.v('GitHub: marking notification $threadId as done');
  await client.request('DELETE', 'notifications/threads/$threadId');
  ref.invalidate(notificationsProvider);
}
