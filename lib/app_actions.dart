import 'package:github/github.dart';
import 'package:tokhub/views.dart';

final class PullRequestsLoadAction {
  final RepositorySlug slug;

  const PullRequestsLoadAction(this.slug);
}

final class PullRequestsLoadedAction {
  final RepositorySlug slug;
  final List<PullRequest> pullRequests;

  const PullRequestsLoadedAction(this.slug, this.pullRequests);
}

final class RepositoriesLoadAction {
  const RepositoriesLoadAction();
}

final class RepositoriesLoadedAction {
  final List<Repository> repositories;

  const RepositoriesLoadedAction(this.repositories);
}

final class SetGitHubAction {
  final GitHub github;

  const SetGitHubAction(this.github);
}

final class SetViewAction {
  final MainView view;

  const SetViewAction(this.view);
}

final class SetTokenAction {
  final String token;

  const SetTokenAction(this.token);
}

final class SetUserAction {
  final CurrentUser? user;

  const SetUserAction(this.user);
}
