import 'dart:typed_data';

import 'types.dart';
import 'errors.dart';
import 'utils.dart';
import 'profiles.dart';
import 'layout_types.dart';

/// Create a new exact-canvas label builder.
///
/// ```dart
/// final myLabel = label(LabelConfig(width: 40, height: 30))
///   .text('Hello World', TextOptions(x: 10, y: 10))
///   .box(BoxOptions(x: 0, y: 0, width: 100, height: 100));
/// ```
LabelBuilder label(LabelConfig config) {
  return LabelBuilder(config);
}

/// Create a sequential document-style label builder.
///
/// Sequential builders automatically track vertical document progression (`_currentY`)
/// and support structured layout helpers like [divider], [space], [row], [rowCells], and [table].
LabelBuilder sequentialLabel(
  LabelConfig config, {
  int? margin,
  int? lineAdvance,
}) {
  return LabelBuilder._sequential(
    config,
    margin: margin,
    lineAdvance: lineAdvance,
  );
}

/// Fluent API for building labels.
class LabelBuilder {
  final LabelConfig _config;
  final List<LabelElement> _elements = [];
  int? _copies;
  final bool _isSequential;
  late final int _startX;
  late final int _lineAdvance;
  late final int _usableWidth;
  int _currentY = 0;

  /// Exact-canvas builder constructor.
  LabelBuilder(this._config)
      : _isSequential = false,
        _startX = 0,
        _lineAdvance = 0,
        _usableWidth = 0 {
    if (_config.width <= 0) {
      throw const InvalidConfigError('width must be greater than 0');
    }
    if (_config.copies != null && _config.copies! < 1) {
      throw InvalidConfigError(
        'copies must be at least 1, got ${_config.copies}',
      );
    }
  }

  /// Private sequential document builder constructor.
  LabelBuilder._sequential(
    this._config, {
    int? margin,
    int? lineAdvance,
  }) : _isSequential = true {
    if (_config.width <= 0) {
      throw const InvalidConfigError('width must be greater than 0');
    }
    if (_config.copies != null && _config.copies! < 1) {
      throw InvalidConfigError(
        'copies must be at least 1, got ${_config.copies}',
      );
    }
    if (margin != null && margin < 0) {
      throw InvalidConfigError('margin must be non-negative, got $margin');
    }
    if (lineAdvance != null && lineAdvance <= 0) {
      throw InvalidConfigError(
        'lineAdvance must be greater than 0, got $lineAdvance',
      );
    }

    int dpi = _config.dpi ?? 203;
    if (_config.printer != null) {
      final profile = getProfile(_config.printer!);
      if (profile != null && _config.dpi == null) {
        dpi = profile.dpi;
      }
    }

    final widthDots = toDots(_config.width, _config.unit, dpi);
    final marginDots = margin ?? toDots(2.5, Unit.mm, dpi);
    final advDots = lineAdvance ?? toDots(3.5, Unit.mm, dpi);

    final usable = widthDots - (2 * marginDots);
    if (usable <= 0) {
      throw InvalidConfigError(
        'Usable label width ($usable dots) must be greater than 0 with margin ($marginDots dots) on label width ($widthDots dots)',
      );
    }

    _startX = marginDots;
    _currentY = marginDots;
    _lineAdvance = advDots;
    _usableWidth = usable;
  }

  void _requireSequential(String method) {
    if (!_isSequential) {
      throw InvalidConfigError(
        '$method requires sequentialLabel(). Call sequentialLabel(config) to enable sequential layout.',
      );
    }
  }

  /// Add a text element.
  ///
  /// In sequential mode ([sequentialLabel]), if both [options.x] and [options.y] are `null`,
  /// the text is positioned at the current sequential cursor `(x: _startX, y: _currentY)`
  /// and `_currentY` advances by `_lineAdvance`.
  /// If either coordinate is supplied, it is treated as an exact-canvas escape hatch and
  /// sequential `_currentY` does not advance.
  LabelBuilder text(String content, [TextOptions? options]) {
    final opts = options ?? const TextOptions();
    if (_isSequential && opts.x == null && opts.y == null) {
      _elements.add(
        TextElement(
          content: content,
          options: TextOptions(
            x: _startX,
            y: _currentY,
            font: opts.font,
            size: opts.size,
            xScale: opts.xScale,
            yScale: opts.yScale,
            rotation: opts.rotation,
            bold: opts.bold,
            underline: opts.underline,
            reverse: opts.reverse,
            align: opts.align,
            maxWidth: opts.maxWidth,
          ),
        ),
      );
      _currentY += _lineAdvance;
    } else {
      _elements.add(TextElement(content: content, options: opts));
    }
    return this;
  }

  /// Advance the vertical document position by [amount] dots without emitting an AST element.
  ///
  /// Requires [sequentialLabel].
  LabelBuilder space(int amount) {
    _requireSequential('space()');
    if (amount < 0) {
      throw InvalidConfigError('space amount must be non-negative, got $amount');
    }
    _currentY += amount;
    return this;
  }

  /// Add a horizontal divider separator across the content area.
  ///
  /// - [thickness]: Line thickness in dots ($\ge 1$, default 1).
  /// - [advance]: Vertical distance in dots to advance `_currentY` (default: `_lineAdvance`).
  /// - [margin]: Additional horizontal inset in dots from both sides of the sequential content area.
  ///
  /// Requires [sequentialLabel].
  LabelBuilder divider({
    int thickness = 1,
    int? advance,
    int? margin,
  }) {
    _requireSequential('divider()');
    if (thickness < 1) {
      throw InvalidConfigError(
        'divider thickness must be at least 1, got $thickness',
      );
    }
    if (advance != null && advance <= 0) {
      throw InvalidConfigError(
        'divider advance must be greater than 0, got $advance',
      );
    }
    if (margin != null && margin < 0) {
      throw InvalidConfigError(
        'divider margin must be non-negative, got $margin',
      );
    }

    final extraMargin = margin ?? 0;
    final dividerStartX = _startX + extraMargin;
    final dividerWidth = _usableWidth - (2 * extraMargin);

    if (dividerWidth <= 0) {
      throw InvalidConfigError(
        'Divider width ($dividerWidth dots) must be greater than 0 with margin ($extraMargin dots) on usable width ($_usableWidth dots)',
      );
    }

    _elements.add(
      DividerElement(
        y: _currentY,
        thickness: thickness,
        startX: dividerStartX,
        width: dividerWidth,
      ),
    );

    _currentY += advance ?? _lineAdvance;
    return this;
  }

  /// Add a simple 2-column key-value row with default 3:1 flex distribution.
  ///
  /// Requires [sequentialLabel].
  LabelBuilder row(
    String left,
    String right, {
    int size = 1,
    bool bold = false,
    int? advance,
  }) {
    return rowCells(
      children: [
        LabelCell.flex(3, text: left, bold: bold),
        LabelCell.flex(1, text: right, align: LabelTextAlign.right, bold: bold),
      ],
      size: size,
      advance: advance,
    );
  }

  /// Add a horizontal row composed of [children] cells with fixed and flex sizing.
  ///
  /// Requires [sequentialLabel].
  LabelBuilder rowCells({
    required List<LabelCell> children,
    int size = 1,
    int gap = 0,
    int? advance,
  }) {
    _requireSequential('rowCells()');
    if (children.isEmpty) {
      throw const InvalidConfigError('rowCells children must not be empty');
    }
    if (size < 1) {
      throw InvalidConfigError('rowCells size must be at least 1, got $size');
    }
    if (gap < 0) {
      throw InvalidConfigError('rowCells gap must be non-negative, got $gap');
    }
    if (advance != null && advance <= 0) {
      throw InvalidConfigError(
        'rowCells advance must be greater than 0, got $advance',
      );
    }

    final allocated = LayoutGeometry.allocateCells(
      startX: _startX,
      availableWidth: _usableWidth,
      gap: gap,
      cells: children,
    );

    final resolvedCells = <RowCellElement>[];
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final geom = allocated[i];
      resolvedCells.add(
        RowCellElement(
          text: child.text,
          x: geom.x,
          width: geom.width,
          align: child.align,
          style: LabelTextStyle(
            bold: child.bold,
            underline: child.underline,
          ),
        ),
      );
    }

    _elements.add(
      RowElement(
        y: _currentY,
        startX: _startX,
        width: _usableWidth,
        size: size,
        cells: resolvedCells,
      ),
    );

    _currentY += advance ?? _lineAdvance;
    return this;
  }

  /// Begin a structured table with fixed column definitions.
  ///
  /// Requires [sequentialLabel].
  LabelTable table({
    required List<LabelColumn> columns,
    int gap = 0,
    int? defaultAdvance,
  }) {
    _requireSequential('table()');
    return LayoutGeometry.createTable(
      this,
      columns: columns,
      gap: gap,
      defaultAdvance: defaultAdvance,
    );
  }

  /// Add an image element.
  LabelBuilder image(MonochromeBitmap bitmap, [ImageOptions? options]) {
    _elements.add(
      ImageElement(bitmap: bitmap, options: options ?? const ImageOptions()),
    );
    return this;
  }

  /// Add a barcode element.
  LabelBuilder barcode(String content, BarcodeOptions options) {
    _elements.add(BarcodeElement(content: content, options: options));
    return this;
  }

  /// Add a QRCode element.
  LabelBuilder qrcode(String content, QRCodeOptions options) {
    _elements.add(QRCodeElement(content: content, options: options));
    return this;
  }

  /// Add a box element.
  LabelBuilder box(BoxOptions options) {
    _elements.add(BoxElement(options: options));
    return this;
  }

  /// Add a line element.
  LabelBuilder line(LineOptions options) {
    _elements.add(LineElement(options: options));
    return this;
  }

  /// Add a circle element.
  LabelBuilder circle(CircleOptions options) {
    _elements.add(CircleElement(options: options));
    return this;
  }

  /// Add an ellipse element.
  LabelBuilder ellipse(EllipseOptions options) {
    _elements.add(EllipseElement(options: options));
    return this;
  }

  /// Add a reverse region.
  LabelBuilder reverse(ReverseOptions options) {
    _elements.add(ReverseElement(options: options));
    return this;
  }

  /// Add an erase region.
  LabelBuilder erase(EraseOptions options) {
    _elements.add(EraseElement(options: options));
    return this;
  }

  /// Add raw binary bytes passthrough, defensively copying the data.
  LabelBuilder rawBytes(Uint8List bytes) {
    _elements.add(RawElement.bytes(bytes));
    return this;
  }

  /// Add raw ASCII command passthrough.
  ///
  /// Throws [UnsupportedCharacterException] if [ascii] contains non-ASCII characters.
  LabelBuilder rawAscii(String ascii) {
    _elements.add(RawElement.ascii(ascii));
    return this;
  }

  /// Add a raw command passthrough.
  @Deprecated('Use rawBytes() or rawAscii() instead. Will be removed in 2.0.')
  LabelBuilder raw(Object content) {
    _elements.add(RawElement(content: content));
    return this;
  }

  /// Set number of copies to print.
  ///
  /// Eagerly validates that [copies] is $\ge 1$.
  LabelBuilder print([int copies = 1]) {
    if (copies < 1) {
      throw InvalidConfigError('copies must be at least 1, got $copies');
    }
    _copies = copies;
    return this;
  }

  /// Resolve the label to its final representation.
  ResolvedLabel resolve() {
    final unit = _config.unit;

    // Check for printer profile
    int dpi = _config.dpi ?? 203;
    if (_config.printer != null) {
      final profile = getProfile(_config.printer!);
      if (profile != null) {
        // Use profile DPI unless user explicitly overrides
        if (_config.dpi == null) {
          dpi = profile.dpi;
        }
      }
    }

    final widthDots = toDots(_config.width, unit, dpi);
    final heightDots =
        _config.height != null ? toDots(_config.height!, unit, dpi) : 0;

    final effectiveCopies = _copies ?? _config.copies ?? 1;
    if (effectiveCopies < 1) {
      throw InvalidConfigError(
        'copies must be at least 1, got $effectiveCopies',
      );
    }

    return ResolvedLabel(
      widthDots: widthDots,
      heightDots: heightDots,
      dpi: dpi,
      speed: _config.speed ?? 4,
      density: _config.density ?? 8,
      direction: _config.direction ?? 0,
      copies: effectiveCopies,
      gap: _config.gap ?? 3,
      gapOffset: _config.gapOffset ?? 0,
      unit: unit,
      elements: List.unmodifiable(_elements),
    );
  }
}
