import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:github/github.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tokhub/logger.dart';
import 'package:tokhub/providers/github.dart';

part 'user.g.dart';

const _logger = Logger(['UserProvider']);

@riverpod
Future<CurrentUser?> currentUser(Ref ref) async {
  final client = await ref.watch(githubClientProvider.future);
  if (client == null) {
    return null;
  }

  _logger.d('Fetching current user');
  try {
    final user = await client.users.getCurrentUser();
    _logger.d('Current user: ${user.login}');
    return user;
  } on AccessForbidden catch (e) {
    _logger.e('Failed to fetch current user: $e');
    return null;
  }
}
