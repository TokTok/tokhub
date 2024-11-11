import 'package:clock/clock.dart';
import 'package:flutter/material.dart';

final class Logger {
  static final List<LogLine> _log = [];
  static bool verbose = false;

  static List<LogLine> get log => List.unmodifiable(_log);

  final List<String> tags;

  const Logger(this.tags);

  void _logLine(LogLevel level, String text, [StackTrace? stackTrace]) {
    if (level == LogLevel.verbose && !verbose) return;
    final line = '${level.name[0].toUpperCase()} $tags $text';
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace, label: line);
      _log.add(LogLine(clock.now(), level, tags, text, stackTrace));
    } else {
      debugPrint(line);
      _log.add(LogLine(clock.now(), level, tags, text));
    }
  }

  void v(String text, [StackTrace? stackTrace]) =>
      _logLine(LogLevel.verbose, text, stackTrace);
  void d(String text, [StackTrace? stackTrace]) =>
      _logLine(LogLevel.debug, text, stackTrace);
  void i(String text, [StackTrace? stackTrace]) =>
      _logLine(LogLevel.info, text, stackTrace);
  void w(String text, [StackTrace? stackTrace]) =>
      _logLine(LogLevel.warning, text, stackTrace);
  void e(String text, [StackTrace? stackTrace]) =>
      _logLine(LogLevel.error, text, stackTrace);

  void logError(Error e, [String? message]) {
    debugPrintStack(
        stackTrace: e.stackTrace,
        label: message != null ? '$tags $message ($e)' : tags.toString());
    _log.add(LogLine(
        clock.now(), LogLevel.warning, tags, '$message ($e)', e.stackTrace));
  }
}

enum LogLevel { verbose, debug, info, warning, error }

final class LogLine {
  final DateTime timestamp;
  final LogLevel level;
  final List<String> tags;
  final String message;
  final StackTrace? stackTrace;

  const LogLine(
    this.timestamp,
    this.level,
    this.tags,
    this.message, [
    this.stackTrace,
  ]);
}
