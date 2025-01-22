import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tokhub/db/database.dart';
import 'package:tokhub/db/shared.dart';
import 'package:tokhub/logger.dart';

part 'database.g.dart';

const _logger = Logger(['DatabaseProvider']);

@riverpod
Future<Database> database(Ref ref) async {
  _logger.d('Opening database');
  final db = await constructDb();
  ref.onDispose(() => db.close());
  _logger.d('Database opened: schema version ${db.schemaVersion}');
  return db;
}
