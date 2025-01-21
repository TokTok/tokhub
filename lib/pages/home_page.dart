import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tokhub/logger.dart';
import 'package:tokhub/models/github.dart';
import 'package:tokhub/pages/settings_page.dart';
import 'package:tokhub/providers/database.dart';
import 'package:tokhub/providers/github.dart';
import 'package:tokhub/providers/repos/pulls.dart';
import 'package:tokhub/providers/orgs/repos.dart';
import 'package:tokhub/providers/settings.dart';
import 'package:tokhub/views.dart';
import 'package:tokhub/widgets/home_view.dart';
import 'package:tokhub/widgets/debug_log_view.dart';
import 'package:tokhub/widgets/pull_requests_view.dart';
import 'package:tokhub/widgets/repositories_view.dart';

class HomePage extends ConsumerWidget {
  static const org = 'TokTok';

  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(settingsProvider).when(
        loading: () => const CircularProgressIndicator(),
        error: (error, _) => Text('Error: $error'),
        data: (settings) => _build(context, ref, settings));
  }

  Widget _build(BuildContext context, WidgetRef ref, SettingsState settings) {
    return Scaffold(
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
                          final style = Theme.of(context).textTheme.bodyMedium;
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
          final db = await ref.read(databaseProvider.future);
          await db.clear();
          await repositoriesRefresh(ref, org);
          for (final repo
              in await ref.watch(repositoriesProvider(org).future)) {
            await pullRequestsRefresh(ref, repo.slug());
            for (final pr
                in await ref.watch(pullRequestsProvider(repo.slug()).future)) {
              await pullRequestRefresh(ref, repo.slug(), pr.number);
            }
          }
        },
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ), // This trailing comma makes auto-formatting nicer for build methods.
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
        return const HomeView();
      case MainView.repos:
        return const RepositoriesView(org: org);
      case MainView.pullRequests:
        return const PullRequestsView(org: org);
      case MainView.settings:
        return const SettingsPage();
      case MainView.logs:
        return DebugLogView(log: Logger.log);
    }
  }
}
