import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tokhub/logger.dart';

final _logger = Logger(['DataObject']);

Future<T?> loadDataObject<T extends DataObject<T>>(
    T Function(Map<String, dynamic> json) fromJson) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/TokHub/${T.toString()}.json');
    debugPrint('Loading data object from ${file.path}');
    if (!await file.exists()) {
      return null;
    }
    final text = await file.readAsString();
    return fromJson(jsonDecode(text));
  } catch (e, stackTrace) {
    _logger.e('Error loading data object: $e', stackTrace);
    return null;
  }
}

Future<void> saveDataObject<T>(DataObject<T> object) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/TokHub/${T.toString()}.json');
    debugPrint('Saving data object to ${file.path}');
    await file.create(recursive: true);
    await file.writeAsString(jsonEncode(object.toJson()));
  } catch (e, stackTrace) {
    _logger.e('Error saving data object: $e', stackTrace);
  }
}

abstract class DataObject<T> {
  Map<String, dynamic> toJson();
}
