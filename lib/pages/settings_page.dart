import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart'
    show HookWidget, useTextEditingController;
import 'package:flutter_redux/flutter_redux.dart';
import 'package:tokhub/app_actions.dart';
import 'package:tokhub/app_state.dart';

final class SettingsPage extends HookWidget {
  final String? token;

  const SettingsPage({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: token);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: const Text('GitHub Token'),
            subtitle: Text(token ?? 'Not set'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('GitHub Token'),
                    content: TextField(
                      controller: controller,
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          StoreProvider.of<AppState>(context)
                              .dispatch(SetTokenAction(controller.value.text));
                          Navigator.pop(context);
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
