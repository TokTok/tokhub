import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tokhub/models/github.dart';
import 'package:tokhub/pages/settings_page.dart';
import 'package:tokhub/providers/github.dart';
import 'package:tokhub/providers/objectbox.dart';
import 'package:tokhub/providers/settings.dart';
import 'package:tokhub/views.dart';
import 'package:tokhub/widgets/pull_requests_view.dart';
import 'package:tokhub/widgets/repositories_view.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(settingsProvider).when(
          loading: () => const CircularProgressIndicator(),
          error: (error, _) => Text('Error: $error'),
          data: (settings) => Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              title: Text(settings.mainView.title),
            ),
            drawer: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TokHub',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        ref.watch(currentUserProvider).when(
                              loading: () => const CircularProgressIndicator(),
                              error: (error, _) => Text('Error: $error'),
                              data: (user) {
                                final style =
                                    Theme.of(context).textTheme.bodyMedium;
                                return user != null
                                    ? Text('Authenticated: ${user.login}',
                                        style: style)
                                    : Text('Not authenticated', style: style);
                              },
                            ),
                      ],
                    ),
                  ),
                  for (final view in MainView.values)
                    ListTile(
                      title: Text('${view.emoji} ${view.title}'),
                      selected: settings.mainView == view,
                      onTap: () {
                        ref.read(settingsProvider.notifier).setMainView(view);
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
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            body: _buildBody(settings.mainView),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                debugPrint('Refreshing');
                final store = await ref.watch(objectBoxProvider.future);
                store.box<StoredRepository>().removeAll();
                store.box<StoredPullRequest>().removeAll();
                ref.invalidate(repositoriesProvider);
                ref.invalidate(pullRequestsProvider);
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
        return const RepositoriesView();
      case MainView.pullRequests:
        return const PullRequestsView();
    }
  }
}
