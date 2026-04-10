import 'dart:typed_data';

/// Unit of measurement for label dimensions.
enum Unit {
  mm,
  inch,
  dot;

  @override
  String toString() {
    switch (this) {
      case Unit.mm:
        return 'mm';
      case Unit.inch:
        return 'inch';
      case Unit.dot:
        return 'dot';
    }
  }

  /// Parse a string to a Unit enum value.
  static Unit fromString(String value) {
    switch (value.toLowerCase()) {
      case 'mm':
        return Unit.mm;
      case 'inch':
        return Unit.inch;
      case 'dot':
        return Unit.dot;
      default:
        return Unit.mm;
    }
  }
}

/// Dithering algorithm for image processing.
enum DitherAlgorithm {
  threshold,
  floydSteinberg,
  atkinson,
  ordered;

  static DitherAlgorithm fromString(String value) {
    switch (value.toLowerCase().replaceAll('-', '').replaceAll('_', '')) {
      case 'threshold':
        return DitherAlgorithm.threshold;
      case 'floydsteinberg':
        return DitherAlgorithm.floydSteinberg;
      case 'atkinson':
        return DitherAlgorithm.atkinson;
      case 'ordered':
        return DitherAlgorithm.ordered;
      default:
        return DitherAlgorithm.threshold;
    }
  }
}

/// Supported printer languages.
enum PrinterLanguage {
  tsc,
  zpl,
  epl,
  escpos,
  cpcl,
  dpl,
  ipl,
  sbpl,
  starprnt;

  @override
  String toString() {
    switch (this) {
      case PrinterLanguage.tsc:
        return 'tsc';
      case PrinterLanguage.zpl:
        return 'zpl';
      case PrinterLanguage.epl:
        return 'epl';
      case PrinterLanguage.escpos:
        return 'escpos';
      case PrinterLanguage.cpcl:
        return 'cpcl';
      case PrinterLanguage.dpl:
        return 'dpl';
      case PrinterLanguage.ipl:
        return 'ipl';
      case PrinterLanguage.sbpl:
        return 'sbpl';
      case PrinterLanguage.starprnt:
        return 'starprnt';
    }
  }
}

/// Options for text elements.
class TextOptions {
  final int? x;
  final int? y;
  final String? font;
  final int? size;
  final int? xScale;
  final int? yScale;
  final int? rotation;
  final bool? bold;
  final bool? underline;
  final bool? reverse;
  final String? align;
  final int? maxWidth;

  const TextOptions({
    this.x,
    this.y,
    this.font,
    this.size,
    this.xScale,
    this.yScale,
    this.rotation,
    this.bold,
    this.underline,
    this.reverse,
    this.align,
    this.maxWidth,
  });
}

/// Options for box elements.
class BoxOptions {
  final int x;
  final int y;
  final int width;
  final int height;
  final int? thickness;
  final int? radius;

  const BoxOptions({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.thickness,
    this.radius,
  });
}

/// Options for line elements.
class LineOptions {
  final int x1;
  final int y1;
  final int x2;
  final int y2;
  final int? thickness;

  const LineOptions({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    this.thickness,
  });
}

/// Options for circle elements.
class CircleOptions {
  final int x;
  final int y;
  final int diameter;
  final int? thickness;

  const CircleOptions({
    required this.x,
    required this.y,
    required this.diameter,
    this.thickness,
  });
}

/// Options for ellipse elements.
class EllipseOptions {
  final int x;
  final int y;
  final int width;
  final int height;
  final int? thickness;

  const EllipseOptions({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.thickness,
  });
}

/// Options for reverse elements.
class ReverseOptions {
  final int x;
  final int y;
  final int width;
  final int height;

  const ReverseOptions({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

/// Options for erase elements.
class EraseOptions {
  final int x;
  final int y;
  final int width;
  final int height;

  const EraseOptions({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

/// Options for image elements.
class ImageOptions {
  final int? x;
  final int? y;
  final int? width;
  final int? height;

  const ImageOptions({this.x, this.y, this.width, this.height});
}

/// Monochrome bitmap (1-bit per pixel, MSB first).
class MonochromeBitmap {
  final Uint8List data;
  final int width;
  final int height;
  final int bytesPerRow;

  const MonochromeBitmap({
    required this.data,
    required this.width,
    required this.height,
    required this.bytesPerRow,
  });
}

/// Sealed class representing all supported label elements.
sealed class LabelElement {
  const LabelElement();

  String get type;
}

/// Text element.
class TextElement extends LabelElement {
  final String content;
  final TextOptions options;

  const TextElement({
    required this.content,
    this.options = const TextOptions(),
  });

  @override
  String get type => 'text';
}

/// Image element.
class ImageElement extends LabelElement {
  final MonochromeBitmap bitmap;
  final ImageOptions options;

  const ImageElement({
    required this.bitmap,
    this.options = const ImageOptions(),
  });

  @override
  String get type => 'image';
}

/// Box element.
class BoxElement extends LabelElement {
  final BoxOptions options;

  const BoxElement({required this.options});

  @override
  String get type => 'box';
}

/// Line element.
class LineElement extends LabelElement {
  final LineOptions options;

  const LineElement({required this.options});

  @override
  String get type => 'line';
}

/// Circle element.
class CircleElement extends LabelElement {
  final CircleOptions options;

  const CircleElement({required this.options});

  @override
  String get type => 'circle';
}

/// Ellipse element.
class EllipseElement extends LabelElement {
  final EllipseOptions options;

  const EllipseElement({required this.options});

  @override
  String get type => 'ellipse';
}

/// Reverse element (inverts colors in a region).
class ReverseElement extends LabelElement {
  final ReverseOptions options;

  const ReverseElement({required this.options});

  @override
  String get type => 'reverse';
}

/// Erase element (clears a region to white).
class EraseElement extends LabelElement {
  final EraseOptions options;

  const EraseElement({required this.options});

  @override
  String get type => 'erase';
}

/// Raw command element (passed through to printer).
class RawElement extends LabelElement {
  final Object content;

  const RawElement({required this.content});

  @override
  String get type => 'raw';
}

/// Configuration for creating a label.
class LabelConfig {
  final double width;
  final double? height;
  final Unit unit;
  final int? dpi;
  final int? speed;
  final int? density;
  final int? direction;
  final int? copies;
  final double? gap;
  final double? gapOffset;
  final String? printer;

  const LabelConfig({
    required this.width,
    this.height,
    this.unit = Unit.mm,
    this.dpi,
    this.speed,
    this.density,
    this.direction,
    this.copies,
    this.gap,
    this.gapOffset,
    this.printer,
  });
}

/// Resolved label — final representation ready for compilation.
class ResolvedLabel {
  final int widthDots;
  final int heightDots;
  final int dpi;
  final int speed;
  final int density;
  final int direction;
  final int copies;
  final double gap;
  final double gapOffset;
  final Unit unit;
  final List<LabelElement> elements;

  const ResolvedLabel({
    required this.widthDots,
    required this.heightDots,
    required this.dpi,
    required this.speed,
    required this.density,
    required this.direction,
    required this.copies,
    required this.gap,
    required this.gapOffset,
    required this.unit,
    required this.elements,
  });
}

/// Options for imageToMonochrome.
class MonochromeOptions {
  final String? dither;
  final int? threshold;

  const MonochromeOptions({this.dither, this.threshold});
}
