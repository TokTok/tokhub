import 'package:redux/redux.dart';
import 'package:tokhub/app_actions.dart';
import 'package:tokhub/app_state.dart';

final appReducer = combineReducers<AppState>([
  TypedReducer<AppState, PullRequestsLoadedAction>(_pullRequestsLoaded).call,
  TypedReducer<AppState, RepositoriesLoadedAction>(_repositoriesLoaded).call,
  TypedReducer<AppState, SetGitHubAction>(_setGitHub).call,
  TypedReducer<AppState, SetTokenAction>(_setToken).call,
  TypedReducer<AppState, SetUserAction>(_setUser).call,
  TypedReducer<AppState, SetViewAction>(_setView).call,
]);

AppState _pullRequestsLoaded(AppState state, PullRequestsLoadedAction action) {
  return state.copyWith(pullRequests: {
    ...state.pullRequests ?? {},
    action.slug: action.pullRequests,
  });
}

AppState _repositoriesLoaded(AppState state, RepositoriesLoadedAction action) {
  return state.copyWith(repositories: action.repositories);
}

AppState _setGitHub(AppState state, SetGitHubAction action) {
  return state.copyWith(github: action.github);
}

AppState _setToken(AppState state, SetTokenAction action) {
  return state.copyWith(token: action.token);
}

AppState _setUser(AppState state, SetUserAction action) {
  return state.copyWith(user: action.user);
}

AppState _setView(AppState state, SetViewAction action) {
  return state.copyWith(mainView: action.view);
}
