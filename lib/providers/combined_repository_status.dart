import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:github/github.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tokhub/logger.dart';
import 'package:tokhub/models/github.dart';
import 'package:tokhub/objectbox.g.dart';
import 'package:tokhub/providers/github.dart';
import 'package:tokhub/providers/objectbox.dart';

part 'combined_repository_status.g.dart';

const _logger = Logger(['CombinedRepositoryStatusProvider']);

@riverpod
Future<MinimalCombinedRepositoryStatus> combinedRepositoryStatus(
  Ref ref,
  MinimalRepository repo,
  MinimalPullRequest pullRequest, {
  required bool force,
}) async {
  final slug = repo.slug();
  final commitSha = pullRequest.head.sha;

  final store = await ref.watch(objectBoxProvider.future);
  final box = store.box<MinimalCombinedRepositoryStatus>();
  final fetched = box
      .query(MinimalCombinedRepositoryStatus_.repository.equals(repo.id) &
          MinimalCombinedRepositoryStatus_.sha.equals(commitSha))
      .build()
      .find();
  if (fetched.isNotEmpty) {
    _logger.v('Found stored combined repository status for $slug@$commitSha '
        '(${fetched.first.statuses?.length} statuses)');
    return fetched.first;
  }

  if (!force &&
      pullRequest.updatedAt!
          .isBefore(DateTime.now().subtract(maxPullRequestAge))) {
    _logger.v('Pull request ${repo.name}/${pullRequest.head.ref} is too old'
        ', not fetching combined statuses');
    return MinimalCombinedRepositoryStatus();
  }

  final id = await ref.watch(
      _fetchAndStoreCombinedRepositoryStatusProvider(repo, commitSha).future);
  return box.get(id)!;
}

Future<void> combinedRepositoryStatusRefresh(
    WidgetRef ref, MinimalRepository repo, String commitSha) async {
  ref.invalidate(
      _fetchAndStoreCombinedRepositoryStatusProvider(repo, commitSha));
  await ref.watch(
      _fetchAndStoreCombinedRepositoryStatusProvider(repo, commitSha).future);
}

@riverpod
Future<int> _fetchAndStoreCombinedRepositoryStatus(
    Ref ref, MinimalRepository repo, String commitSha) async {
  final slug = repo.slug();

  final store = await ref.watch(objectBoxProvider.future);
  final box = store.box<MinimalCombinedRepositoryStatus>();

  // Fetch the combined status from GitHub.
  final status = await ref
      .watch(_githubCombinedRepositoryStatusProvider(slug, commitSha).future);

  // Delete existing combined status for the same commit.
  box
      .query(MinimalCombinedRepositoryStatus_.repository.equals(repo.id) &
          MinimalCombinedRepositoryStatus_.sha.equals(commitSha))
      .build()
      .remove();

  // Store the new combined status.
  final id = box.put(status);
  _logger.v('Stored combined repository status: $slug@$commitSha '
      '(${status.statuses?.length} statuses)');

  return id;
}

@riverpod
Future<MinimalCombinedRepositoryStatus> _githubCombinedRepositoryStatus(
    Ref ref, RepositorySlug slug, String commitSha) async {
  final client = await ref.watch(githubClientProvider.future);
  if (client == null) {
    throw StateError('No client available');
  }

  _logger.d('Fetching commit status for $slug@$commitSha');
  return client.getJSON<Map<String, dynamic>, MinimalCombinedRepositoryStatus>(
    '/repos/$slug/commits/$commitSha/status',
    convert: MinimalCombinedRepositoryStatus.fromJson,
    statusCode: StatusCodes.OK,
  );
}
