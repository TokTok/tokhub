import 'dart:io';

import 'package:tokhub/db/database.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

Future<Database> constructDb() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File(path.join(dbFolder.path, 'TokHub', 'db.sqlite'));
  return Database(NativeDatabase(file));
}
