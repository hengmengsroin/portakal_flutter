import 'builder.dart';
import 'errors.dart';
import 'types.dart';

/// Sizing and styling specification for a cell in a structured row.
sealed class LabelCell {
  final String text;
  final LabelTextAlign align;
  final bool bold;
  final bool underline;

  const LabelCell({
    required this.text,
    this.align = LabelTextAlign.left,
    this.bold = false,
    this.underline = false,
  });

  /// Fixed-width cell with exact width in dots.
  factory LabelCell.fixed(
    int width, {
    required String text,
    LabelTextAlign align,
    bool bold,
    bool underline,
  }) = _FixedLabelCell;

  /// Proportional flex cell distributing available row width by integer weight.
  factory LabelCell.flex(
    int flex, {
    required String text,
    LabelTextAlign align,
    bool bold,
    bool underline,
  }) = _FlexLabelCell;
}

class _FixedLabelCell extends LabelCell {
  final int width;
  _FixedLabelCell(
    this.width, {
    required super.text,
    super.align = LabelTextAlign.left,
    super.bold = false,
    super.underline = false,
  }) {
    if (width <= 0) {
      throw InvalidConfigError(
        'Fixed cell width must be greater than 0, got $width',
      );
    }
  }
}

class _FlexLabelCell extends LabelCell {
  final int flex;
  _FlexLabelCell(
    this.flex, {
    required super.text,
    super.align = LabelTextAlign.left,
    super.bold = false,
    super.underline = false,
  }) {
    if (flex <= 0) {
      throw InvalidConfigError('Flex weight must be greater than 0, got $flex');
    }
  }
}

/// Sizing and alignment definition for a table column.
sealed class LabelColumn {
  final LabelTextAlign align;
  const LabelColumn({this.align = LabelTextAlign.left});

  /// Fixed-width column with exact width in dots.
  factory LabelColumn.fixed(
    int width, {
    LabelTextAlign align,
  }) = _FixedLabelColumn;

  /// Proportional flex column distributing available table width by integer weight.
  factory LabelColumn.flex(
    int flex, {
    LabelTextAlign align,
  }) = _FlexLabelColumn;
}

class _FixedLabelColumn extends LabelColumn {
  final int width;
  _FixedLabelColumn(this.width, {super.align = LabelTextAlign.left}) {
    if (width <= 0) {
      throw InvalidConfigError(
        'Fixed column width must be greater than 0, got $width',
      );
    }
  }
}

class _FlexLabelColumn extends LabelColumn {
  final int flex;
  _FlexLabelColumn(this.flex, {super.align = LabelTextAlign.left}) {
    if (flex <= 0) {
      throw InvalidConfigError('Flex weight must be greater than 0, got $flex');
    }
  }
}

/// Structured table helper for repeated row generation sharing the parent builder's sequential state.
abstract interface class LabelTable {
  /// Add a row of text cells matching the table column definitions.
  LabelTable row(
    List<String> cells, {
    int size = 1,
    bool bold = false,
    int? advance,
  });

  /// Add a horizontal divider line across the table width.
  LabelTable divider({int thickness = 1, int? advance, int? margin});

  /// Advance vertical document space by [amount] dots without emitting an AST element.
  LabelTable space(int amount);
}

class _LabelTable implements LabelTable {
  final LabelBuilder _builder;
  final List<LabelColumn> _columns;
  final int _gap;
  final int? _defaultAdvance;

  _LabelTable(
    this._builder, {
    required List<LabelColumn> columns,
    int gap = 0,
    int? defaultAdvance,
  })  : _columns = List.unmodifiable(columns),
        _gap = gap,
        _defaultAdvance = defaultAdvance {
    if (_columns.isEmpty) {
      throw const InvalidConfigError('Table columns must not be empty');
    }
    if (gap < 0) {
      throw InvalidConfigError('Table gap must be non-negative, got $gap');
    }
    if (defaultAdvance != null && defaultAdvance <= 0) {
      throw InvalidConfigError(
        'Table defaultAdvance must be greater than 0, got $defaultAdvance',
      );
    }
  }

  @override
  LabelTable row(
    List<String> cells, {
    int size = 1,
    bool bold = false,
    int? advance,
  }) {
    if (cells.length != _columns.length) {
      throw InvalidConfigError(
        'Table row cell count (${cells.length}) does not match column count (${_columns.length})',
      );
    }
    if (size < 1) {
      throw InvalidConfigError('Table row size must be at least 1, got $size');
    }
    if (advance != null && advance <= 0) {
      throw InvalidConfigError(
        'Table row advance must be greater than 0, got $advance',
      );
    }

    final children = <LabelCell>[];
    for (var i = 0; i < cells.length; i++) {
      final text = cells[i];
      final col = _columns[i];
      switch (col) {
        case _FixedLabelColumn(:final width):
          children.add(
            LabelCell.fixed(
              width,
              text: text,
              align: col.align,
              bold: bold,
            ),
          );
        case _FlexLabelColumn(:final flex):
          children.add(
            LabelCell.flex(
              flex,
              text: text,
              align: col.align,
              bold: bold,
            ),
          );
      }
    }

    _builder.rowCells(
      children: children,
      size: size,
      gap: _gap,
      advance: advance ?? _defaultAdvance,
    );

    return this;
  }

  @override
  LabelTable divider({int thickness = 1, int? advance, int? margin}) {
    _builder.divider(
      thickness: thickness,
      advance: advance ?? _defaultAdvance,
      margin: margin,
    );
    return this;
  }

  @override
  LabelTable space(int amount) {
    _builder.space(amount);
    return this;
  }
}

/// Sizing specification for column width allocation.
typedef ColumnSizingSpec = ({int? fixedWidth, int? flex});

/// Internal deterministic width allocator for structured rows and tables.
class LayoutGeometry {
  /// Allocates cell coordinates and widths for a list of [LabelCell] definitions.
  static List<({int x, int width})> allocateCells({
    required int startX,
    required int availableWidth,
    int gap = 0,
    required List<LabelCell> cells,
  }) {
    final specs = cells.map((cell) {
      return switch (cell) {
        _FixedLabelCell(:final width) => (fixedWidth: width, flex: null),
        _FlexLabelCell(:final flex) => (fixedWidth: null, flex: flex),
      };
    }).toList();

    return allocateColumns(
      startX: startX,
      availableWidth: availableWidth,
      gap: gap,
      specs: specs,
    );
  }

  /// Internal factory for constructing a [LabelTable] implementation.
  static LabelTable createTable(
    LabelBuilder builder, {
    required List<LabelColumn> columns,
    int gap = 0,
    int? defaultAdvance,
  }) {
    return _LabelTable(
      builder,
      columns: columns,
      gap: gap,
      defaultAdvance: defaultAdvance,
    );
  }

  /// Allocates column coordinates and widths across [availableWidth] dots.
  ///
  /// - [startX]: Starting X coordinate for the first column.
  /// - [availableWidth]: Total width in dots available for columns and gaps.
  /// - [gap]: Horizontal spacing in dots between adjacent columns.
  /// - [specs]: List of column sizing specifications (fixed width or flex weight).
  ///
  /// Throws [InvalidConfigError] if:
  /// - [specs] is empty.
  /// - [availableWidth] <= 0.
  /// - [gap] < 0.
  /// - any fixed width <= 0 or flex weight <= 0.
  /// - total fixed widths plus total gaps exceed [availableWidth].
  static List<({int x, int width})> allocateColumns({
    required int startX,
    required int availableWidth,
    required int gap,
    required List<ColumnSizingSpec> specs,
  }) {
    if (specs.isEmpty) {
      throw const InvalidConfigError('Column specifications must not be empty');
    }
    if (availableWidth <= 0) {
      throw InvalidConfigError(
        'Available width must be greater than 0, got $availableWidth',
      );
    }
    if (gap < 0) {
      throw InvalidConfigError('Gap must be non-negative, got $gap');
    }

    for (var i = 0; i < specs.length; i++) {
      final s = specs[i];
      if (s.fixedWidth != null && s.fixedWidth! <= 0) {
        throw InvalidConfigError(
          'Fixed column width must be greater than 0 at index $i, got ${s.fixedWidth}',
        );
      }
      if (s.flex != null && s.flex! <= 0) {
        throw InvalidConfigError(
          'Flex weight must be greater than 0 at index $i, got ${s.flex}',
        );
      }
      if (s.fixedWidth == null && s.flex == null) {
        throw InvalidConfigError(
          'Column spec at index $i must specify either fixedWidth or flex',
        );
      }
    }

    final count = specs.length;
    if (count == 1) {
      final w = specs[0].fixedWidth ?? availableWidth;
      if (w > availableWidth) {
        throw InvalidConfigError(
          'Fixed column width ($w) exceeds available width ($availableWidth)',
        );
      }
      return [(x: startX, width: w)];
    }

    final totalGaps = (count - 1) * gap;
    final usableWidth = availableWidth - totalGaps;
    if (usableWidth < 0) {
      throw InvalidConfigError(
        'Total gaps ($totalGaps) exceed available width ($availableWidth)',
      );
    }

    var totalFixed = 0;
    var totalFlex = 0;
    var totalFlexCount = 0;

    for (final s in specs) {
      if (s.fixedWidth != null) {
        totalFixed += s.fixedWidth!;
      } else {
        totalFlex += s.flex!;
        totalFlexCount++;
      }
    }

    final flexPool = usableWidth - totalFixed;
    if (flexPool < 0) {
      throw InvalidConfigError(
        'Fixed column widths ($totalFixed) plus gaps ($totalGaps) exceed available width ($availableWidth)',
      );
    }

    if (totalFlexCount > 0 && totalFlex <= 0) {
      throw const InvalidConfigError('Total flex weight must be greater than 0');
    }

    final result = <({int x, int width})>[];
    var currentX = startX;
    var allocatedFlexDots = 0;
    var flexColumnsSeen = 0;

    for (final s in specs) {
      int colWidth;
      if (s.fixedWidth != null) {
        colWidth = s.fixedWidth!;
      } else {
        flexColumnsSeen++;
        final weight = s.flex!;
        if (flexColumnsSeen == totalFlexCount) {
          // The final flex column receives the exact remainder:
          colWidth = flexPool - allocatedFlexDots;
        } else {
          colWidth = (weight * flexPool) ~/ totalFlex;
          allocatedFlexDots += colWidth;
        }
      }

      result.add((x: currentX, width: colWidth));
      currentX += colWidth + gap;
    }

    return result;
  }
}
