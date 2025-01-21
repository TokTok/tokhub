import 'package:drift/drift.dart';

abstract class JsonEnum<T> {
  String get string;
}

final class JsonEnumConverter<T extends JsonEnum<T>>
    extends TypeConverter<T, String>
    with JsonTypeConverter2<T, String, String> {
  final List<T> values;

  const JsonEnumConverter(this.values);

  @override
  T fromJson(String json) {
    return fromSql(json);
  }

  @override
  T fromSql(String fromDb) {
    return values.firstWhere((element) => element.string == fromDb);
  }

  @override
  String toJson(T value) {
    return toSql(value);
  }

  @override
  String toSql(T value) {
    return value.string;
  }
}
