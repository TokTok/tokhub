import 'package:tokhub/models/github.dart';

final class PullRequestInfo {
  /// The repository to which the pull request belongs.
  final StoredRepository repo;
  final StoredPullRequest pr;

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

  /// Title of pull request.
  final String title;

  /// The mergeability state of the PR (clean = it's mergeable now).
  final PullRequestMergeableState state;

  /// Whether the PR is a draft.
  final bool draft;

  /// The head commit SHA of the PR.
  final String commitSha;

  const PullRequestInfo({
    required this.repo,
    required this.pr,
    required this.number,
    required this.url,
    required this.user,
    required this.avatar,
    required this.branch,
    required this.title,
    required this.state,
    required this.draft,
    required this.commitSha,
  });

  factory PullRequestInfo.from(StoredRepository repo, StoredPullRequest pr) {
    return PullRequestInfo(
      repo: repo,
      pr: pr,
      number: pr.data.number,
      url: Uri.parse(pr.data.htmlUrl),
      user: pr.data.user.login,
      avatar: pr.data.user.avatarUrl,
      branch: pr.data.head.ref,
      title: pr.data.title,
      state: PullRequestMergeableState.values.firstWhere(
        (s) => s.name == pr.data.mergeableState,
        orElse: () => PullRequestMergeableState.unknown,
      ),
      draft: pr.data.draft,
      commitSha: pr.data.head.sha,
    );
  }
}

enum PullRequestMergeableState {
  clean('✅'),
  behind('💤'),
  blocked('🚧'),
  draft('📝'),
  dirty('❌'),
  unknown('⌛'),
  unstable('🚧');

  final String emoji;

  const PullRequestMergeableState(this.emoji);
}
