import 'dart:math';

import 'errors.dart';
import 'types.dart';

/// Internal styled segment of a formatted stream line.
class StreamRowSegment {
  /// Formatted text content of this segment.
  final String text;

  /// Whether emphasized (bold) style is active for this segment.
  final bool bold;

  /// Whether underline style is active for this segment.
  final bool underline;

  const StreamRowSegment({
    required this.text,
    this.bold = false,
    this.underline = false,
  });
}

/// Internal execution plan for emitting one physical stream line.
class StreamRowPlan {
  /// Character height/width magnification multiplier (>= 1).
  final int size;

  /// Ordered list of styled and unstyled text segments for the line.
  final List<StreamRowSegment> segments;

  const StreamRowPlan({
    required this.size,
    required this.segments,
  });
}

/// Internal pure-Dart formatter that maps physical [RowElement] and [DividerElement]
/// geometry into a discrete monospaced character grid for stream/receipt printers.
class StreamRowFormatter {
  const StreamRowFormatter._();

  /// Resolves the base character capacity (columns) for the given label.
  ///
  /// Standard Font A capacity:
  /// - <= 60mm physical media (e.g. 58mm roll): 32 characters
  /// - > 60mm physical media (e.g. 80mm roll): 48 characters
  ///
  /// If [charsPerLineOverride] is provided, it must be > 0 and overrides automatic detection.
  static int resolveBaseCharsPerLine(
    ResolvedLabel label, [
    int? charsPerLineOverride,
  ]) {
    if (charsPerLineOverride != null) {
      if (charsPerLineOverride <= 0) {
        throw InvalidConfigError(
          'Stream charsPerLine override must be positive, got: $charsPerLineOverride',
        );
      }
      return charsPerLineOverride;
    }

    if (label.widthDots <= 0 || label.dpi <= 0) {
      return 48;
    }

    final widthMm = (label.widthDots / label.dpi) * 25.4;
    return widthMm <= 60.0 ? 32 : 48;
  }

  /// Formats a semantic [RowElement] into a discrete [StreamRowPlan].
  static StreamRowPlan formatRow(
    ResolvedLabel label,
    RowElement row, {
    int? charsPerLine,
  }) {
    if (label.widthDots <= 0) {
      throw InvalidConfigError(
        'Label widthDots must be positive, got: ${label.widthDots}',
      );
    }
    if (row.width <= 0) {
      throw InvalidConfigError(
        'Row width must be positive, got: ${row.width}',
      );
    }
    if (row.startX < 0) {
      throw InvalidConfigError(
        'Row startX must be non-negative, got: ${row.startX}',
      );
    }
    if (row.size < 1) {
      throw InvalidConfigError(
        'Row size must be at least 1, got: ${row.size}',
      );
    }

    final baseChars = resolveBaseCharsPerLine(label, charsPerLine);
    final effectiveChars = baseChars ~/ row.size;
    if (effectiveChars < 1) {
      throw InvalidConfigError(
        'Effective character capacity must be at least 1 (base: $baseChars, size: ${row.size})',
      );
    }

    final marginSpaces =
        (row.startX * effectiveChars / label.widthDots).floor();
    final rowChars = (row.width * effectiveChars / label.widthDots).floor();

    if (marginSpaces + rowChars > effectiveChars) {
      throw InvalidConfigError(
        'Row width plus margin ($marginSpaces + $rowChars = ${marginSpaces + rowChars} chars) exceeds effective capacity ($effectiveChars chars)',
      );
    }

    final cells = row.cells;
    if (cells.isEmpty) {
      return StreamRowPlan(size: row.size, segments: const []);
    }

    // Validate cell geometry and layout bounds
    for (int i = 0; i < cells.length; i++) {
      final cell = cells[i];
      if (cell.width <= 0) {
        throw InvalidConfigError(
          'RowCell width must be positive, got: ${cell.width} at index $i',
        );
      }
      if (cell.x < row.startX) {
        throw InvalidConfigError(
          'RowCell x (${cell.x}) cannot precede row startX (${row.startX}) at index $i',
        );
      }
      if (cell.x + cell.width > row.startX + row.width) {
        throw InvalidConfigError(
          'RowCell (${cell.x} + ${cell.width}) exceeds row bounds (${row.startX + row.width}) at index $i',
        );
      }
      if (i > 0) {
        final prev = cells[i - 1];
        if (cell.x < prev.x + prev.width) {
          throw InvalidConfigError(
            'Overlapping RowCells at index $i (x: ${cell.x}, prev end: ${prev.x + prev.width})',
          );
        }
      }
    }

    // Derive segment widths in character columns
    // Segments: cell0, gap0, cell1, gap1, ..., cell_{N-1}
    final segmentCharWidths = <int>[];
    int allocatedChars = 0;

    for (int i = 0; i < cells.length; i++) {
      final cell = cells[i];
      final isLast = (i == cells.length - 1);

      if (!isLast) {
        // Cell allocation
        final cellChars =
            max(1, (cell.width * effectiveChars / label.widthDots).floor());
        segmentCharWidths.add(cellChars);
        allocatedChars += cellChars;

        // Gap allocation
        final nextCell = cells[i + 1];
        final gapDots = nextCell.x - (cell.x + cell.width);
        final gapChars = (gapDots * effectiveChars / label.widthDots).floor();
        segmentCharWidths.add(gapChars);
        allocatedChars += gapChars;
      } else {
        // Final cell receives exact remainder
        final remainingChars = rowChars - allocatedChars;
        if (remainingChars < 1) {
          throw InvalidConfigError(
            'Stream row character budget ($rowChars chars) is too narrow for ${cells.length} cells',
          );
        }
        segmentCharWidths.add(remainingChars);
      }
    }

    final segments = <StreamRowSegment>[];

    // Leading margin spaces
    if (marginSpaces > 0) {
      segments.add(StreamRowSegment(text: ' ' * marginSpaces));
    }

    int segIndex = 0;
    for (int i = 0; i < cells.length; i++) {
      final cell = cells[i];
      final cellChars = segmentCharWidths[segIndex++];

      final formattedText = _formatCellText(cell, cellChars);
      segments.add(
        StreamRowSegment(
          text: formattedText,
          bold: cell.style.bold,
          underline: cell.style.underline,
        ),
      );

      if (i < cells.length - 1) {
        final gapChars = segmentCharWidths[segIndex++];
        if (gapChars > 0) {
          segments.add(StreamRowSegment(text: ' ' * gapChars));
        }
      }
    }

    return StreamRowPlan(
      size: row.size,
      segments: List.unmodifiable(segments),
    );
  }

  /// Formats a semantic [DividerElement] into a discrete [StreamRowPlan].
  static StreamRowPlan formatDivider(
    ResolvedLabel label,
    DividerElement divider, {
    int? charsPerLine,
  }) {
    if (label.widthDots <= 0) {
      throw InvalidConfigError(
        'Label widthDots must be positive, got: ${label.widthDots}',
      );
    }
    if (divider.width <= 0) {
      throw InvalidConfigError(
        'Divider width must be positive, got: ${divider.width}',
      );
    }
    if (divider.startX < 0) {
      throw InvalidConfigError(
        'Divider startX must be non-negative, got: ${divider.startX}',
      );
    }

    final baseChars = resolveBaseCharsPerLine(label, charsPerLine);
    final marginSpaces =
        (divider.startX * baseChars / label.widthDots).floor();
    final dividerChars =
        max(1, (divider.width * baseChars / label.widthDots).floor());

    final fillChar = divider.thickness > 1 ? '=' : '-';
    final leading = ' ' * marginSpaces;
    final content = fillChar * dividerChars;

    return StreamRowPlan(
      size: 1,
      segments: [
        StreamRowSegment(text: leading + content),
      ],
    );
  }

  /// Truncates runes safely and applies horizontal padding to match [cellChars].
  static String _formatCellText(RowCellElement cell, int cellChars) {
    final runes = cell.text.runes.toList(growable: false);

    String visibleText;
    int runeLen;

    if (runes.length > cellChars) {
      // Rune-safe truncation: never split UTF-16 surrogate pairs
      visibleText = String.fromCharCodes(runes.sublist(0, cellChars));
      runeLen = cellChars;
    } else {
      visibleText = cell.text;
      runeLen = runes.length;
    }

    final extra = cellChars - runeLen;
    if (extra <= 0) {
      return visibleText;
    }

    switch (cell.align) {
      case LabelTextAlign.left:
        return visibleText + (' ' * extra);
      case LabelTextAlign.right:
        return (' ' * extra) + visibleText;
      case LabelTextAlign.center:
        final leftPad = extra ~/ 2;
        final rightPad = extra - leftPad;
        return (' ' * leftPad) + visibleText + (' ' * rightPad);
    }
  }
}
