import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tokhub/providers/settings.dart';
import 'package:tokhub/widgets/settings_string_tile.dart';

final class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return settings.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, _) => Text('Error: $error'),
      data: (settings) => Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: ListView(
          children: [
            SettingsStringTile(
              value: settings.token,
              onSave: (value) {
                ref.read(settingsProvider.notifier).setToken(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
