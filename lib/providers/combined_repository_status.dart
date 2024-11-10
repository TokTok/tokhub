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

Future<void> combinedRepositoryStatusRefresh(
    WidgetRef ref, StoredRepository repo, StoredPullRequest pullRequest) async {
  final commitSha = pullRequest.data.head.sha;
  final store = await ref.watch(objectBoxProvider.future);
  final box = store.box<StoredCombinedRepositoryStatus>();
  box
      .query(StoredCombinedRepositoryStatus_.sha.equals(commitSha))
      .build()
      .remove();
  ref.invalidate(combinedRepositoryStatusProvider(repo, pullRequest));
}

@riverpod
Future<StoredCombinedRepositoryStatus> combinedRepositoryStatus(
  Ref ref,
  StoredRepository repo,
  StoredPullRequest pullRequest, {
  bool force = false,
}) async {
  final slug = repo.data.slug();
  final commitSha = pullRequest.data.head.sha;

  final store = await ref.watch(objectBoxProvider.future);
  final box = store.box<StoredCombinedRepositoryStatus>();
  final fetched = box
      .query(StoredCombinedRepositoryStatus_.repo.equals(slug.fullName) &
          StoredCombinedRepositoryStatus_.sha.equals(commitSha))
      .build()
      .find();
  if (fetched.isNotEmpty) {
    _logger.v('Found stored combined repository status for $slug@$commitSha '
        '(${fetched.first.data.statuses?.length} statuses)');
    return fetched.first;
  }

  if (!force &&
      pullRequest.data.updatedAt!
          .isBefore(DateTime.now().subtract(maxPullRequestAge))) {
    _logger.d(
        'Pull request ${repo.data.name}/${pullRequest.data.head.ref} is too old'
        ', not fetching combined statuses');
    return StoredCombinedRepositoryStatus();
  }

  final status = await ref
      .watch(_githubCombinedRepositoryStatusProvider(slug, commitSha).future);
  final id = box.put(StoredCombinedRepositoryStatus()..data = status);
  _logger.v('Stored combined repository status: $slug@$commitSha '
      '(${status.statuses?.length} statuses)');
  return box.get(id)!;
}

@riverpod
Future<CombinedRepositoryStatus> _githubCombinedRepositoryStatus(
    Ref ref, RepositorySlug slug, String commitSha) async {
  final client = await ref.watch(githubClientProvider.future);
  if (client == null) {
    throw StateError('No client available');
  }

  _logger.d('Checking commit status for $slug@$commitSha');
  return client.repositories.getCombinedStatus(slug, commitSha);
}
