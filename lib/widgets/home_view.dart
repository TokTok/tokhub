import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tokhub/db/database.dart';
import 'package:tokhub/providers/database.dart';

final class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(databaseProvider).when(
        loading: () => const CircularProgressIndicator(),
        error: (error, stacktrace) => Text('Error: $error\n$stacktrace'),
        data: (data) => _build(data, ref));
  }

  Widget _build(Database db, WidgetRef ref) {
    return FutureBuilder(
        future: db.select(db.minimalRepository).get(),
        builder: (context, snapshot) {
          final repositories = snapshot.data;
          if (snapshot.connectionState != ConnectionState.done ||
              repositories == null) {
            return const CircularProgressIndicator();
          }

          return ListView.builder(
            itemCount: repositories.length,
            itemBuilder: (context, index) {
              final repository = repositories[index];
              return ListTile(
                title: Text(repository.name),
                subtitle: Text(repository.fullName),
              );
            },
          );
        });
  }
}
