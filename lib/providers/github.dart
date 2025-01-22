import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:github/github.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tokhub/providers/settings.dart';

part 'github.g.dart';

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
