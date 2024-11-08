import 'package:github/github.dart';
import 'package:tokhub/views.dart';

final class AppState {
  final MainView mainView;
  final GitHub? github;
  final CurrentUser? user;
  final String? token;

  final List<Repository>? repositories;
  final Map<RepositorySlug, List<PullRequest>>? pullRequests;

  const AppState({
    required this.mainView,
    required this.github,
    required this.user,
    required this.token,
    required this.repositories,
    required this.pullRequests,
  });

  factory AppState.fromJson(Map<String, dynamic> json) {
    return const AppState.initialState().copyWith(
      mainView: MainView.values.firstWhere(
        (v) => v.name == json['mainView'],
        orElse: () => MainView.home,
      ),
      user: CurrentUser.fromJson(json['user']),
      token: json['token'],
      repositories: (json['repositories'] as List<dynamic>?)
          ?.map((r) => Repository.fromJson(r))
          .toList(growable: false),
      pullRequests:
          (json['pullRequests'] as Map<String, dynamic>?)?.map((k, v) {
        final slug = RepositorySlug.full(k);
        final prs = (v as List<dynamic>)
            .map((pr) => PullRequest.fromJson(pr))
            .toList(growable: false);
        return MapEntry(slug, prs);
      }),
    );
  }

  const AppState.initialState()
      : mainView = MainView.home,
        github = null,
        user = null,
        token = null,
        repositories = null,
        pullRequests = null;

  AppState copyWith({
    MainView? mainView,
    GitHub? github,
    CurrentUser? user,
    String? token,
    List<Repository>? repositories,
    Map<RepositorySlug, List<PullRequest>>? pullRequests,
  }) {
    return AppState(
      mainView: mainView ?? this.mainView,
      github: github ?? this.github,
      user: user ?? this.user,
      token: token ?? this.token,
      repositories: repositories ?? this.repositories,
      pullRequests: pullRequests ?? this.pullRequests,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mainView': mainView.name,
      'user': user?.toJson(),
      'token': token,
      'repositories':
          repositories?.map((r) => r.toJson()).toList(growable: false),
      'pullRequests': pullRequests?.map((k, v) {
        return MapEntry(
            k.fullName, v.map((pr) => pr.toJson()).toList(growable: false));
      }),
    };
  }
}
