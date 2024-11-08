import 'dart:async';

import 'package:flutter/material.dart';
import 'package:github/github.dart';
import 'package:redux/redux.dart';
import 'package:tokhub/app_actions.dart';
import 'package:tokhub/app_state.dart';
import 'package:tokhub/storage.dart';

final class AppMiddleware implements MiddlewareClass<AppState> {
  Timer? _timer;

  AppMiddleware();

  @override
  dynamic call(
      Store<AppState> store, dynamic action, NextDispatcher next) async {
    final stopwatch = Stopwatch()..start();
    switch (action) {
      case SetTokenAction _:
        if (action.token.isEmpty) {
          break;
        }
        final github = GitHub(auth: Authentication.withToken(action.token));
        store.dispatch(SetGitHubAction(github));
        try {
          final user = await github.users.getCurrentUser();
          debugPrint(
              'Got current user: ${user.login} (${stopwatch.elapsedMilliseconds}ms)');
          store.dispatch(SetUserAction(user));
        } catch (e) {
          debugPrint('Failed to get current user: $e');
          store.dispatch(const SetUserAction(null));
        }
        break;

      case RepositoriesLoadAction _:
        final github = store.state.github;
        if (github == null) {
          break;
        }
        final repos = await github.repositories
            .listOrganizationRepositories('TokTok')
            .toList();
        repos.sort((a, b) => a.name.compareTo(b.name));
        debugPrint(
            'Got ${repos.length} repositories (${stopwatch.elapsedMilliseconds}ms)');
        store.dispatch(RepositoriesLoadedAction(repos));
        for (final repo in repos) {
          store.dispatch(PullRequestsLoadAction(repo.slug()));
        }
        break;

      case PullRequestsLoadAction _:
        final github = store.state.github;
        if (github == null) {
          break;
        }
        final pullRequests =
            await github.pullRequests.list(action.slug).toList();
        debugPrint(
            'Got ${pullRequests.length} pull requests for ${action.slug.fullName} (${stopwatch.elapsedMilliseconds}ms)');
        store.dispatch(PullRequestsLoadedAction(action.slug, pullRequests));
        break;
    }

    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 5), () {
      saveState(store.state);
    });

    return next(action);
  }
}
