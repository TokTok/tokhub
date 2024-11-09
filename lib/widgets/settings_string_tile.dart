import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

final class SettingsStringTile extends HookWidget {
  final String? value;
  final void Function(String value) onSave;

  const SettingsStringTile({
    super.key,
    required this.value,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: value);
    return ListTile(
      title: const Text('GitHub Token'),
      subtitle: Text(value ?? 'Not set'),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('GitHub Token'),
              content: TextField(
                controller: controller,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    onSave(controller.value.text);
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
