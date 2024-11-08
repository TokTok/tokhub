import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:github/github.dart';
import 'package:tokhub/app_actions.dart';
import 'package:tokhub/app_state.dart';
import 'package:tokhub/pages/settings_page.dart';
import 'package:tokhub/views.dart';
import 'package:tokhub/widgets/repositories_view.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, MainView>(
      converter: (store) => store.state.mainView,
      builder: (context, mainView) => Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(mainView.title),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TokHub',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.inversePrimary,
                        fontSize: 24,
                      ),
                    ),
                    StoreConnector<AppState, String?>(
                      converter: (store) => store.state.user?.login,
                      builder: (context, user) {
                        final style = TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary,
                        );
                        return user != null
                            ? Text('Authenticated: $user', style: style)
                            : Text('Not authenticated', style: style);
                      },
                    ),
                  ],
                ),
              ),
              for (final view in MainView.values)
                ListTile(
                  title: Text('${view.emoji} ${view.title}'),
                  selected: mainView == view,
                  onTap: () {
                    StoreProvider.of<AppState>(context)
                        .dispatch(SetViewAction(view));
                    Navigator.pop(context);
                  },
                ),
              ListTile(
                title: const Text('🛠️ Settings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StoreConnector<AppState, String?>(
                        converter: (store) => store.state.token,
                        builder: (context, token) => SettingsPage(
                          token: token,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        body: _buildBody(mainView),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            final store = StoreProvider.of<AppState>(context);
            switch (mainView) {
              case MainView.home:
                store.dispatch(const RepositoriesLoadAction());
                break;
              case MainView.repos:
                store.dispatch(const RepositoriesLoadAction());
                break;
              case MainView.pulls:
                store.dispatch(const RepositoriesLoadAction());
                break;
            }
          },
          tooltip: 'Refresh',
          child: const Icon(Icons.refresh),
        ), // This trailing comma makes auto-formatting nicer for build methods.
      ),
    );
  }

  Widget _buildBody(MainView view) {
    switch (view) {
      case MainView.home:
        return const Center(
          child: Text('Home'),
        );
      case MainView.repos:
        return StoreConnector<AppState,
            (List<Repository>, Map<RepositorySlug, List<PullRequest>>)>(
          converter: (store) =>
              (store.state.repositories ?? [], store.state.pullRequests ?? {}),
          builder: (context, data) {
            final (repositories, pullRequests) = data;
            return RepositoriesView(
              repositories: repositories,
              pullRequests: pullRequests,
            );
          },
        );
      case MainView.pulls:
        return const Center(
          child: Text('Pull Requests'),
        );
    }
  }
}
