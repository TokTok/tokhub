enum MainView {
  home(MainViewSection.main, 'Home', '🏠'),
  repos(MainViewSection.main, 'Repositories', '📦'),
  pullRequests(MainViewSection.main, 'Pull Requests', '🔀'),
  settings(MainViewSection.settings, 'Settings', '🛠️', push: true),
  logs(MainViewSection.debug, 'Logs', '🪵');

  final MainViewSection section;
  final String title;
  final String emoji;

  /// Whether to push the view to the navigation stack.
  final bool push;

  const MainView(this.section, this.title, this.emoji, {this.push = false});
}

enum MainViewSection {
  main,
  settings,
  debug,
}
