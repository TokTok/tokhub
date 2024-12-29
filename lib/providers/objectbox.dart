import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tokhub/logger.dart';

import '../objectbox.g.dart';
part 'objectbox.g.dart';

const _logger = Logger(['ObjectBox']);

@riverpod
Future<Store> objectBox(Ref ref) async {
  final directory = await getApplicationDocumentsDirectory();
  final path = p.join(directory.path, 'TokHub', 'objectbox');
  final dir = await Directory(path).create(recursive: true);
  _logger.i('ObjectBox directory: ${dir.path}');
  final store = await openStore(
    directory: path,
    macosApplicationGroup: '83SSMZ4T7X.tokhub',
  );
  ref.onDispose(() => store.close());
  return store;
}
