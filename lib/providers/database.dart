import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tokhub/db/database.dart';
import 'package:tokhub/db/shared.dart';

part 'database.g.dart';

@riverpod
Future<Database> database(Ref ref) async {
  final db = constructDb();
  ref.onDispose(() => db.then((value) => value.close()));
  return db;
}
