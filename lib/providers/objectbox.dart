import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../objectbox.g.dart';
part 'objectbox.g.dart';

@riverpod
Future<Store> objectBox(Ref ref) async {
  final directory = await getApplicationDocumentsDirectory();
  final path = p.join(directory.path, 'TokHub', 'objectbox');
  final store = await openStore(directory: path);
  ref.onDispose(() => store.close());
  return store;
}
