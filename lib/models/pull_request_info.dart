import 'package:github/github.dart';

final class PullRequestInfo {
  /// The repository for which the pull request is.
  final String repoName;

  /// The assigned pull request issue number.
  final int number;

  /// The URL to the pull request.
  final Uri url;

  /// The user who proposed this PR.
  final String user;

  /// The avatar URL of the user who proposed this PR.
  final String avatar;

  /// The branch name from which the pull request came.
  final String branch;

  /// Creation time of pull request. I.e. when it was proposed.
  final DateTime created;

  /// Title of pull request.
  final String title;

  /// The mergeability state of the PR (clean = it's mergeable now).
  final PullRequestState state;

  /// The origin repository as user/reponame string.
  final String? origin;

  const PullRequestInfo({
    required this.repoName,
    required this.number,
    required this.url,
    required this.user,
    required this.avatar,
    required this.branch,
    required this.created,
    required this.title,
    required this.state,
    required this.origin,
  });

  factory PullRequestInfo.from(PullRequest pr) {
    return PullRequestInfo(
      repoName: pr.base!.repo!.fullName,
      number: pr.number!,
      url: Uri.parse(pr.htmlUrl!),
      user: pr.user!.login!,
      avatar: pr.user!.avatarUrl!,
      branch: pr.head!.ref!,
      created: pr.createdAt!,
      title: pr.title!,
      state: PullRequestState.values.firstWhere(
        (s) => s.name == pr.mergeableState,
        orElse: () => PullRequestState.unknown,
      ),
      origin: pr.head!.repo!.fullName,
    );
  }
}

enum PullRequestState {
  clean('✅'),
  behind('💤'),
  blocked('🚧'),
  draft('📝'),
  dirty('❌'),
  unknown('⌛'),
  unstable('🚧');

  final String emoji;

  const PullRequestState(this.emoji);
}
