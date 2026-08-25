import 'dart:convert';
import 'dart:typed_data';

import 'encoding.dart';

/// Policy for handling unsupported elements or features in target compiler.
enum UnsupportedFeaturePolicy {
  /// Throws [UnsupportedFeatureError] when an unsupported element is encountered.
  throwError,

  /// Silently omits or skips the unsupported element.
  ignore,
}

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

/// Options for barcode elements.
class BarcodeOptions {
  final int x;
  final int y;
  final String type; // e.g. "128", "39", "EAN13"
  final int height;
  final int? readable; // 0: not readable, 1: human readable
  final int? rotation;
  final int? narrow;
  final int? wide;
  final int? alignment;

  const BarcodeOptions({
    required this.x,
    required this.y,
    required this.type,
    required this.height,
    this.readable,
    this.rotation,
    this.narrow,
    this.wide,
    this.alignment,
  });
}

/// Options for QRCode elements.
class QRCodeOptions {
  final int x;
  final int y;
  final String? eccLevel; // L, M, Q, H
  final int? cellWidth; // 1-10
  final String? mode; // A, M
  final int? rotation;
  final String? model;
  final String? mask;

  const QRCodeOptions({
    required this.x,
    required this.y,
    this.eccLevel,
    this.cellWidth,
    this.mode,
    this.rotation,
    this.model,
    this.mask,
  });
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

/// Barcode element.
class BarcodeElement extends LabelElement {
  final String content;
  final BarcodeOptions options;

  const BarcodeElement({required this.content, required this.options});

  @override
  String get type => 'barcode';
}

/// QRCode element.
class QRCodeElement extends LabelElement {
  final String content;
  final QRCodeOptions options;

  const QRCodeElement({required this.content, required this.options});

  @override
  String get type => 'qrcode';
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

/// Raw command element (passed through to printer as canonical byte sequence).
class RawElement extends LabelElement {
  final Uint8List bytes;

  /// Creates a raw element from binary bytes, defensively copying the data.
  RawElement.bytes(Uint8List rawBytes) : bytes = Uint8List.fromList(rawBytes);

  /// Creates a raw element from a byte list, defensively copying the data.
  RawElement.fromList(List<int> rawList) : bytes = Uint8List.fromList(rawList);

  /// Creates a raw element from ASCII text.
  ///
  /// Throws [UnsupportedCharacterException] if any character is outside the standard 7-bit ASCII range (0x00-0x7F).
  RawElement.ascii(String text) : bytes = _validateAndEncodeAscii(text);

  /// Legacy constructor accepting Object (String, Uint8List, `List<int>`).
  @Deprecated(
    'Use RawElement.bytes or RawElement.ascii instead. Will be removed in 2.0.',
  )
  RawElement({required Object content})
    : bytes = _convertLegacyContent(content);

  static Uint8List _validateAndEncodeAscii(String text) {
    final list = <int>[];
    for (final rune in text.runes) {
      if (rune > 0x7F) {
        throw UnsupportedCharacterException(
          character: String.fromCharCode(rune),
          codePoint: rune,
          codePage: PrinterCodePage.cp437,
          message:
              'Non-ASCII character "$text" contains U+${rune.toRadixString(16).padLeft(4, '0').toUpperCase()} which cannot be encoded in ASCII raw command.',
        );
      }
      list.add(rune);
    }
    return Uint8List.fromList(list);
  }

  static Uint8List _convertLegacyContent(Object content) {
    if (content is Uint8List) {
      return Uint8List.fromList(content);
    } else if (content is List<int>) {
      return Uint8List.fromList(content);
    } else if (content is String) {
      return Uint8List.fromList(latin1.encode(content));
    } else {
      return Uint8List.fromList(latin1.encode(content.toString()));
    }
  }

  /// Legacy content getter for backward compatibility.
  @Deprecated('Use bytes instead. Will be removed in 2.0.')
  Object get content => bytes;

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
