enum MainView {
  home('Home', '🏠'),
  repos('Repositories', '📦'),
  pullRequests('Pull Requests', '🔀');

  final String title;
  final String emoji;

  const MainView(this.title, this.emoji);
}
