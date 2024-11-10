import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tokhub/data_object.dart';
import 'package:tokhub/logger.dart';
import 'package:tokhub/views.dart';

part 'settings.freezed.dart';
part 'settings.g.dart';

const _logger = Logger(['SettingsProvider']);

@riverpod
final class Settings extends _$Settings {
  Timer? _saveTimer;

  @override
  Future<SettingsState> build() async {
    return await loadDataObject(SettingsState.fromJson) ??
        const SettingsState(mainView: MainView.home, token: null);
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
    _saveTimer = Timer(const Duration(seconds: 2), () {
      state.whenData((data) => saveDataObject(data));
    });
  }
}

@freezed
sealed class SettingsState
    with _$SettingsState
    implements DataObject<SettingsState> {
  const factory SettingsState({
    @Default(MainView.home) MainView mainView,
    required String? token,
  }) = _Settings;

  factory SettingsState.fromJson(Map<String, dynamic> json) =>
      _$SettingsStateFromJson(json);
}
