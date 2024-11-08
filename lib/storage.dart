import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tokhub/app_state.dart';

const _stateFile = 'tokhub.json';

Future<AppState> loadState() async {
  try {
    final timer = Stopwatch()..start();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_stateFile');
    debugPrint('Loading state from ${file.path}');
    final text = await file.readAsString();
    final json = jsonDecode(text);
    debugPrint(
        'Loaded state (${_showSize(text.length)}) in ${timer.elapsedMilliseconds}ms');
    return AppState.fromJson(json);
  } catch (e) {
    debugPrint('Failed to load state: $e');
    return const AppState.initialState();
  }
}

Future<void> saveState(AppState state) async {
  final timer = Stopwatch()..start();
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$_stateFile');
  debugPrint('Saving state to ${file.path}');
  final text = jsonEncode(state.toJson());
  file.writeAsString(text);
  debugPrint(
      'Saved state (${_showSize(text.length)}) in ${timer.elapsedMilliseconds}ms');
}

String _showSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes bytes';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(2)} KiB';
  }
  return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MiB';
}
