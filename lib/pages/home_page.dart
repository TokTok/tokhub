import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tokhub/logger.dart';
import 'package:tokhub/models/github.dart';
import 'package:tokhub/pages/settings_page.dart';
import 'package:tokhub/providers/check_runs.dart';
import 'package:tokhub/providers/combined_repository_status.dart';
import 'package:tokhub/providers/github.dart';
import 'package:tokhub/providers/objectbox.dart';
import 'package:tokhub/providers/pull_request.dart';
import 'package:tokhub/providers/repository.dart';
import 'package:tokhub/providers/settings.dart';
import 'package:tokhub/views.dart';
import 'package:tokhub/widgets/debug_log_view.dart';
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
                      image: const DecorationImage(
                        image: AssetImage('assets/images/tokhub.png'),
                        fit: BoxFit.none,
                        alignment: Alignment.centerRight,
                        scale: 7,
                        opacity: 0.7,
                      ),
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
                  ..._buildDrawerItems(context, ref, settings),
                ],
              ),
            ),
            body: _buildBody(settings.mainView),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                debugPrint('Refreshing');
                final store = await ref.watch(objectBoxProvider.future);
                store.box<MinimalCheckRun>().removeAll();
                store.box<MinimalCombinedRepositoryStatus>().removeAll();
                store.box<MinimalPullRequest>().removeAll();
                store.box<MinimalRepository>().removeAll();
                ref.invalidate(checkRunsProvider);
                ref.invalidate(combinedRepositoryStatusProvider);
                ref.invalidate(combinedRepositoryStatusProvider);
                ref.invalidate(pullRequestsProvider);
                ref.invalidate(repositoriesProvider);
              },
              tooltip: 'Refresh',
              child: const Icon(Icons.refresh),
            ), // This trailing comma makes auto-formatting nicer for build methods.
          ),
        );
  }

  List<Widget> _buildDrawerItems(
      BuildContext context, WidgetRef ref, SettingsState settings) {
    final widgets = <Widget>[];
    var section = MainView.values[0].section;
    for (final view in MainView.values) {
      if (view.section != section) {
        section = view.section;
        widgets.add(const Divider());
      }
      widgets.add(view.push
          ? ListTile(
              title: Text('${view.emoji} ${view.title}'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => _buildBody(view)),
                );
              },
            )
          : ListTile(
              title: Text('${view.emoji} ${view.title}'),
              selected: settings.mainView == view,
              onTap: () {
                ref.read(settingsProvider.notifier).setMainView(view);
                Navigator.pop(context);
              },
            ));
    }
    return widgets;
  }

  Widget _buildBody(MainView view) {
    switch (view) {
      case MainView.home:
        return const Center(
          child: Text('Home'),
        );
      case MainView.repos:
        return const RepositoriesView(org: 'TokTok');
      case MainView.pullRequests:
        return const PullRequestsView(org: 'TokTok');
      case MainView.settings:
        return const SettingsPage();
      case MainView.logs:
        return DebugLogView(log: Logger.log);
    }
  }
}
