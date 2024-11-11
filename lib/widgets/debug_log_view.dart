import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tokhub/logger.dart';

TextStyle _styleForLevel(LogLevel level) {
  switch (level) {
    case LogLevel.verbose:
      return const TextStyle(color: Colors.grey);
    case LogLevel.debug:
      return const TextStyle(color: Colors.grey);
    case LogLevel.info:
      return const TextStyle(color: Colors.blue);
    case LogLevel.warning:
      return const TextStyle(color: Colors.orange);
    case LogLevel.error:
      return const TextStyle(color: Colors.red);
  }
}

final class DebugLogView extends HookWidget {
  final List<LogLine> log;

  const DebugLogView({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final searchTerm = useState('');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: (value) => searchTerm.value = value,
          decoration: const InputDecoration(
            labelText: 'Search',
            hintText: 'text or tag',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Table(
                defaultColumnWidth: const IntrinsicColumnWidth(),
                children: log.reversed
                    .where(
                      (line) {
                        final search = searchTerm.value.toLowerCase();
                        return line.message.toLowerCase().contains(search) ||
                            line.tags.any(
                                (tag) => tag.toLowerCase().contains(search));
                      },
                    )
                    .take(1000)
                    .map((line) {
                      final style = _styleForLevel(line.level);
                      return TableRow(
                        children: [
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(line.timestamp.toIso8601String(),
                                  style: style),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                  line.level.name.toString()[0].toUpperCase(),
                                  style: style),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(line.tags.toString(), style: style),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(line.message, style: style),
                            ),
                          ),
                        ],
                      );
                    })
                    .toList(growable: false),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
