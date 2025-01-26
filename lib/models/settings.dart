import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tokhub/models/views.dart';

part 'settings.freezed.dart';
part 'settings.g.dart';

@freezed
sealed class SettingsState with _$SettingsState {
  const factory SettingsState({
    @Default(MainView.home) MainView mainView,
    String? token,
  }) = _Settings;

  factory SettingsState.fromJson(Map<String, dynamic> json) =>
      _$SettingsStateFromJson(json);
}
