import 'package:drift/drift.dart';
import 'package:tokhub/models/check_status.dart';
import 'package:tokhub/models/github.dart';
import 'package:tokhub/models/json_enum.dart';
import 'package:tokhub/models/settings.dart';
import 'package:tokhub/models/settings_table.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  MinimalCheckRun,
  MinimalCommitStatus,
  MinimalPullRequest,
  MinimalRepository,
  MinimalUser,
  SettingsTable,
])
final class Database extends _$Database {
  Database(super.e);

  @override
  int get schemaVersion => 1;

  Future<void> clear() async {
    await transaction(() async {
      await delete(minimalCheckRun).go();
      await delete(minimalCommitStatus).go();
      await delete(minimalPullRequest).go();
      await delete(minimalRepository).go();
      await delete(minimalUser).go();
    });
  }
}
