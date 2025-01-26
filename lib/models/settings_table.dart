import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tokhub/models/settings.dart';

final class SettingsStateConverter extends TypeConverter<SettingsState, String>
    with JsonTypeConverter2<SettingsState, String, Map<String, dynamic>> {
  const SettingsStateConverter();

  @override
  SettingsState fromJson(Map<String, dynamic> json) {
    return SettingsState.fromJson(json);
  }

  @override
  SettingsState fromSql(String fromDb) {
    return fromJson(jsonDecode(fromDb));
  }

  @override
  Map<String, dynamic> toJson(SettingsState value) {
    return value.toJson();
  }

  @override
  String toSql(SettingsState value) {
    return jsonEncode(toJson(value));
  }
}

class SettingsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get settings => text().map(const SettingsStateConverter())();
}
