import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tokhub/models/github.dart';
import 'package:tokhub/models/pull_request_info.dart';
import 'package:tokhub/providers/pull_request.dart';
import 'package:tokhub/providers/repository.dart';

part 'pull_request_info.g.dart';

@riverpod
Future<List<PullRequestInfo>> pullRequestInfo(
  Ref ref,
  MinimalRepository repo,
) async {
  final prs = (await ref.watch(pullRequestsProvider(repo).future))
      .map((pr) => PullRequestInfo.from(repo, pr))
      .toList(growable: false);
  prs.sort((a, b) => b.number.compareTo(a.number));
  return prs;
}

@riverpod
Future<List<(MinimalRepository, List<PullRequestInfo>)>> pullRequestInfos(
  Ref ref, {
  required String org,
}) async {
  final repos = await ref.watch(repositoriesProvider(org: org).future);
  repos.sort((a, b) => a.name.compareTo(b.name));
  return (await Future.wait(repos.map((repo) async =>
          (repo, await ref.watch(pullRequestInfoProvider(repo).future)))))
      .where((element) => element.$2.isNotEmpty)
      .toList(growable: false);
}
