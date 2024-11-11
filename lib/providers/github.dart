import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:github/github.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tokhub/logger.dart';
import 'package:tokhub/providers/settings.dart';

part 'github.g.dart';

/// The maximum age of a pull request to fetch check runs and statuses for.
const maxPullRequestAge = Duration(days: 180);

const _logger = Logger(['GitHubProvider']);

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

// Provider for the GitHub client.
@riverpod
Future<GitHub?> githubClient(Ref ref) async {
  final token = await ref.watch(_githubTokenProvider.future);
  if (token == null) {
    return null;
  }

  return GitHub(auth: Authentication.withToken(token));
}

// Dedicated provider for the token.
@riverpod
Future<String?> _githubToken(Ref ref) async {
  final settings = await ref.watch(settingsProvider.future);
  return settings.token;
}
