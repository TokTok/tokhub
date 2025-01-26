import 'dart:io';

import 'package:tokhub/db/database.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:tokhub/logger.dart';

const _logger = Logger(['DatabaseProvider']);

Future<Database> constructDb() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File(path.join(dbFolder.path, 'TokHub', 'db.sqlite'));
  _logger.v('Opening database: ${file.path}');
  return Database(NativeDatabase(file));
}
