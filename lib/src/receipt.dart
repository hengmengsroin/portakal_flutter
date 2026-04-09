

/// Column definition for receipt table formatting.
class Column {
  final int width;
  final String align;

  const Column({required this.width, this.align = 'left'});
}

/// Format a left+right pair on a single line.
///
/// ```dart
/// formatPair('Hamburger', '\$12.99', 32)
/// // "Hamburger                      \$12.99"
/// ```
String formatPair(String left, String right, int lineWidth) {
  final available = lineWidth - left.length;
  if (available <= 0) {
    return left.substring(0, lineWidth);
  }
  if (right.length > available) {
    return left + right.substring(right.length - available);
  }
  return left + right.padLeft(available);
}

/// Format a multi-column row.
String formatRow(List<Column> columns, List<String> values, int lineWidth) {
  final buf = StringBuffer();

  for (int i = 0; i < columns.length; i++) {
    final col = columns[i];
    final value = i < values.length ? values[i] : '';
    final truncated = value.length > col.width
        ? value.substring(0, col.width)
        : value;

    String cell;
    switch (col.align) {
      case 'right':
        cell = truncated.padLeft(col.width);
      case 'center':
        final padTotal = col.width - truncated.length;
        final padLeft = padTotal ~/ 2;
        final padRight = padTotal - padLeft;
        cell = ' ' * padLeft + truncated + ' ' * padRight;
      default:
        cell = truncated.padRight(col.width);
    }
    buf.write(cell);
  }

  final result = buf.toString();
  if (result.length > lineWidth) return result.substring(0, lineWidth);
  return result.padRight(lineWidth);
}

/// Format multiple rows as a table.
List<String> formatTable(
    List<Column> columns, List<List<String>> rows, int lineWidth) {
  return rows.map((row) => formatRow(columns, row, lineWidth)).toList();
}

/// Create a separator line of repeated characters.
String separator(String char, int lineWidth) {
  return char * lineWidth;
}

/// Word-wrap text to fit within a line width.
List<String> wordWrap(String text, int lineWidth) {
  if (text.isEmpty) return [''];

  final words = text.split(' ');
  final lines = <String>[];
  var currentLine = '';

  for (final word in words) {
    if (currentLine.isEmpty) {
      currentLine = word;
    } else if (currentLine.length + 1 + word.length <= lineWidth) {
      currentLine += ' $word';
    } else {
      lines.add(currentLine);
      currentLine = word;
    }
  }

  if (currentLine.isNotEmpty) {
    lines.add(currentLine);
  }

  return lines;
}
