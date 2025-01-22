import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tokhub/db/database.dart';
import 'package:tokhub/logger.dart';
import 'package:tokhub/models/settings.dart';
import 'package:tokhub/providers/database.dart';
import 'package:tokhub/models/views.dart';

part 'settings.g.dart';

const _logger = Logger(['SettingsProvider']);

@riverpod
final class Settings extends _$Settings {
  Timer? _saveTimer;

  @override
  Future<SettingsState> build() async {
    final db = await ref.watch(databaseProvider.future);
    return await db.select(db.settingsTable).getSingle().then((row) {
      return SettingsState.fromJson(row.toJson());
    }).catchError((e) {
      _logger.d('No settings; creating fresh settings: $e');
      return const SettingsState();
    });
  }

  void setMainView(MainView mainView) {
    _logger.v('setMainView: $mainView');
    state = state.whenData((data) => data.copyWith(mainView: mainView));
    _save();
  }

  void setToken(String? token) async {
    _logger.v('setToken: $token');
    state = state.whenData((data) => data.copyWith(token: token));
    _save();
  }

  void _save() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () async {
      state.whenData((data) async {
        final db = await ref.read(databaseProvider.future);
        await db
            .into(db.settingsTable)
            .insertOnConflictUpdate(SettingsTableData(id: 0, settings: data));
      });
    });
  }
}
