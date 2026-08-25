import 'dart:math';
import 'dart:typed_data';

import 'barcode_encoder.dart';
import 'builder.dart';
import 'qr_encoder.dart';
import 'types.dart';

/// Preview color palette for monochromatic thermal output representation.
enum PreviewColor {
  black,
  white,
}

/// Placeholder type classification for non-rendered visual codes.
enum PreviewPlaceholderKind {
  barcode,
  qrCode,
}

/// A contiguous horizontal span of black pixels within a monochrome bitmap.
class PreviewBitmapSpan {
  final int y;
  final int xStart;
  final int pixelCount;
  final double targetX;
  final double targetY;
  final double targetWidth;
  final double targetHeight;

  const PreviewBitmapSpan({
    required this.y,
    required this.xStart,
    required this.pixelCount,
    required this.targetX,
    required this.targetY,
    required this.targetWidth,
    required this.targetHeight,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreviewBitmapSpan &&
          runtimeType == other.runtimeType &&
          y == other.y &&
          xStart == other.xStart &&
          pixelCount == other.pixelCount &&
          targetX == other.targetX &&
          targetY == other.targetY &&
          targetWidth == other.targetWidth &&
          targetHeight == other.targetHeight;

  @override
  int get hashCode => Object.hash(
        y,
        xStart,
        pixelCount,
        targetX,
        targetY,
        targetWidth,
        targetHeight,
      );
}

/// Canonical, platform-agnostic geometric primitive in a [PreviewScene].
sealed class PreviewItem {
  const PreviewItem();
}

/// Normalized text element.
class PreviewTextItem extends PreviewItem {
  final double x;
  final double y;
  final String text;
  final int fontSize;
  final int xScale;
  final int yScale;
  final int rotation;
  final bool bold;
  final bool underline;
  final bool isReverse;
  final String? font;
  final String? align;
  final int? maxWidth;
  final double baselineOffset;
  final double svgY;
  final double textAnchorX;
  final String svgAnchor;

  const PreviewTextItem({
    required this.x,
    required this.y,
    required this.text,
    required this.fontSize,
    required this.xScale,
    required this.yScale,
    required this.rotation,
    required this.bold,
    required this.underline,
    required this.isReverse,
    required this.font,
    required this.align,
    required this.maxWidth,
    required this.baselineOffset,
    required this.svgY,
    required this.textAnchorX,
    required this.svgAnchor,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreviewTextItem &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          text == other.text &&
          fontSize == other.fontSize &&
          xScale == other.xScale &&
          yScale == other.yScale &&
          rotation == other.rotation &&
          bold == other.bold &&
          underline == other.underline &&
          isReverse == other.isReverse &&
          font == other.font &&
          align == other.align &&
          maxWidth == other.maxWidth &&
          baselineOffset == other.baselineOffset &&
          svgY == other.svgY &&
          textAnchorX == other.textAnchorX &&
          svgAnchor == other.svgAnchor;

  @override
  int get hashCode => Object.hashAll([
        x,
        y,
        text,
        fontSize,
        xScale,
        yScale,
        rotation,
        bold,
        underline,
        isReverse,
        font,
        align,
        maxWidth,
        baselineOffset,
        svgY,
        textAnchorX,
        svgAnchor,
      ]);
}

/// Normalized rectangle element (box, reverse, erase, or filled region).
class PreviewRectItem extends PreviewItem {
  final double x;
  final double y;
  final double width;
  final double height;
  final double thickness;
  final double radius;
  final bool isFilled;
  final PreviewColor color;

  const PreviewRectItem({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.thickness,
    required this.radius,
    required this.isFilled,
    required this.color,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreviewRectItem &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          width == other.width &&
          height == other.height &&
          thickness == other.thickness &&
          radius == other.radius &&
          isFilled == other.isFilled &&
          color == other.color;

  @override
  int get hashCode => Object.hash(
        x,
        y,
        width,
        height,
        thickness,
        radius,
        isFilled,
        color,
      );
}

/// Normalized straight line element.
class PreviewLineItem extends PreviewItem {
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double thickness;
  final PreviewColor color;

  const PreviewLineItem({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.thickness,
    required this.color,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreviewLineItem &&
          runtimeType == other.runtimeType &&
          x1 == other.x1 &&
          y1 == other.y1 &&
          x2 == other.x2 &&
          y2 == other.y2 &&
          thickness == other.thickness &&
          color == other.color;

  @override
  int get hashCode => Object.hash(x1, y1, x2, y2, thickness, color);
}

/// Normalized circle element.
class PreviewCircleItem extends PreviewItem {
  final double cx;
  final double cy;
  final double radius;
  final double thickness;
  final bool isFilled;
  final PreviewColor color;

  const PreviewCircleItem({
    required this.cx,
    required this.cy,
    required this.radius,
    required this.thickness,
    required this.isFilled,
    required this.color,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreviewCircleItem &&
          runtimeType == other.runtimeType &&
          cx == other.cx &&
          cy == other.cy &&
          radius == other.radius &&
          thickness == other.thickness &&
          isFilled == other.isFilled &&
          color == other.color;

  @override
  int get hashCode => Object.hash(cx, cy, radius, thickness, isFilled, color);
}

/// Normalized oval / ellipse element.
class PreviewOvalItem extends PreviewItem {
  final double cx;
  final double cy;
  final double rx;
  final double ry;
  final double thickness;
  final PreviewColor color;

  const PreviewOvalItem({
    required this.cx,
    required this.cy,
    required this.rx,
    required this.ry,
    required this.thickness,
    required this.color,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreviewOvalItem &&
          runtimeType == other.runtimeType &&
          cx == other.cx &&
          cy == other.cy &&
          rx == other.rx &&
          ry == other.ry &&
          thickness == other.thickness &&
          color == other.color;

  @override
  int get hashCode => Object.hash(cx, cy, rx, ry, thickness, color);
}

/// Visual 1D barcode element composed of exact bar spans.
class PreviewBarcodeItem extends PreviewItem {
  final double x;
  final double y;
  final double width;
  final double height;
  final int rotation;
  final String symbology;
  final String payload;
  final bool readable;
  final List<PreviewBitmapSpan> bars;

  const PreviewBarcodeItem({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotation,
    required this.symbology,
    required this.payload,
    required this.readable,
    required this.bars,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PreviewBarcodeItem || runtimeType != other.runtimeType) {
      return false;
    }
    if (x != other.x ||
        y != other.y ||
        width != other.width ||
        height != other.height ||
        rotation != other.rotation ||
        symbology != other.symbology ||
        payload != other.payload ||
        readable != other.readable ||
        bars.length != other.bars.length) {
      return false;
    }
    for (var i = 0; i < bars.length; i++) {
      if (bars[i] != other.bars[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        x,
        y,
        width,
        height,
        rotation,
        symbology,
        payload,
        readable,
        Object.hashAll(bars),
      );
}

/// Visual 2D QR code element composed of exact module spans.
class PreviewQrItem extends PreviewItem {
  final double x;
  final double y;
  final double width;
  final double height;
  final int rotation;
  final String payload;
  final int moduleSize;
  final int matrixSize;
  final List<PreviewBitmapSpan> modules;

  const PreviewQrItem({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotation,
    required this.payload,
    required this.moduleSize,
    required this.matrixSize,
    required this.modules,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PreviewQrItem || runtimeType != other.runtimeType) {
      return false;
    }
    if (x != other.x ||
        y != other.y ||
        width != other.width ||
        height != other.height ||
        rotation != other.rotation ||
        payload != other.payload ||
        moduleSize != other.moduleSize ||
        matrixSize != other.matrixSize ||
        modules.length != other.modules.length) {
      return false;
    }
    for (var i = 0; i < modules.length; i++) {
      if (modules[i] != other.modules[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        x,
        y,
        width,
        height,
        rotation,
        payload,
        moduleSize,
        matrixSize,
        Object.hashAll(modules),
      );
}

/// Deterministic layout placeholder fallback for unsupported or unencodable visual codes.
class PreviewPlaceholderItem extends PreviewItem {
  final double x;
  final double y;
  final double width;
  final double height;
  final int rotation;
  final PreviewPlaceholderKind kind;
  final String typeName;
  final String payload;
  final String label;

  const PreviewPlaceholderItem({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotation,
    required this.kind,
    required this.typeName,
    required this.payload,
    required this.label,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreviewPlaceholderItem &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          width == other.width &&
          height == other.height &&
          rotation == other.rotation &&
          kind == other.kind &&
          typeName == other.typeName &&
          payload == other.payload &&
          label == other.label;

  @override
  int get hashCode => Object.hash(
        x,
        y,
        width,
        height,
        rotation,
        kind,
        typeName,
        payload,
        label,
      );
}

/// Normalized monochrome bitmap image composed of horizontal black pixel spans.
class PreviewBitmapItem extends PreviewItem {
  final double x;
  final double y;
  final double width;
  final double height;
  final int sourceWidth;
  final int sourceHeight;
  final List<PreviewBitmapSpan> spans;

  const PreviewBitmapItem({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.spans,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PreviewBitmapItem || runtimeType != other.runtimeType) {
      return false;
    }
    if (x != other.x ||
        y != other.y ||
        width != other.width ||
        height != other.height ||
        sourceWidth != other.sourceWidth ||
        sourceHeight != other.sourceHeight ||
        spans.length != other.spans.length) {
      return false;
    }
    for (var i = 0; i < spans.length; i++) {
      if (spans[i] != other.spans[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        x,
        y,
        width,
        height,
        sourceWidth,
        sourceHeight,
        Object.hashAll(spans),
      );
}

/// Canonical, immutable intermediate representation of a resolved label scene.
class PreviewScene {
  final int widthDots;
  final int heightDots;
  final int dpi;
  final String? languageName;
  final List<PreviewItem> items;

  const PreviewScene({
    required this.widthDots,
    required this.heightDots,
    required this.dpi,
    this.languageName,
    required this.items,
  });

  /// Constructs a [PreviewScene] from a [ResolvedLabel].
  factory PreviewScene.fromResolved(
    ResolvedLabel label, {
    String? languageName,
  }) {
    final w = label.widthDots;
    final h = label.heightDots > 0 ? label.heightDots : 400;
    final items = <PreviewItem>[];

    for (final el in label.elements) {
      final item = _convertElement(el);
      if (item != null) {
        items.add(item);
      }
    }

    return PreviewScene(
      widthDots: w,
      heightDots: h,
      dpi: label.dpi,
      languageName: languageName,
      items: List.unmodifiable(items),
    );
  }

  /// Constructs a [PreviewScene] directly from a [LabelBuilder].
  factory PreviewScene.fromBuilder(
    LabelBuilder builder, {
    String? languageName,
  }) {
    return PreviewScene.fromResolved(
      builder.resolve(),
      languageName: languageName,
    );
  }

  /// Calculates font pixel size based on AST options.
  static int calcFontSize(int? size, int? yScale) {
    if (yScale != null && yScale > 10) return yScale;
    return max(8, (size ?? 1) * 12);
  }

  /// Baseline offset ratio based on font type.
  static double baselineRatio(String? font) {
    return font == '0' ? 0.78 : 0.82;
  }

  /// Font family selection helper.
  static String fontFamily(String? font) {
    if (font == '0') return "'Helvetica Neue', Helvetica, Arial, sans-serif";
    return 'monospace';
  }

  static PreviewItem? _convertElement(LabelElement el) {
    switch (el) {
      case TextElement():
        final o = el.options;
        final x = (o.x ?? 0).toDouble();
        final y = (o.y ?? 0).toDouble();
        final fs = calcFontSize(o.size, o.yScale);
        final bl = baselineRatio(o.font);
        final weightBold = o.bold == true;
        final isUnderline = o.underline == true;
        final isRev = o.reverse == true;
        final rot = o.rotation ?? 0;
        final xMul = max(1, min(10, o.xScale ?? 1));
        final yMul = max(1, min(10, o.yScale ?? 1));

        var anchor = 'start';
        var textAnchorX = x;
        if (o.maxWidth != null && o.align == 'center') {
          anchor = 'middle';
          textAnchorX = x + o.maxWidth! / 2.0;
        } else if (o.maxWidth != null && o.align == 'right') {
          anchor = 'end';
          textAnchorX = x + o.maxWidth!.toDouble();
        }

        final svgY = ((y + fs * bl) * 100).round() / 100.0;

        return PreviewTextItem(
          x: x,
          y: y,
          text: el.content,
          fontSize: fs,
          xScale: xMul,
          yScale: yMul,
          rotation: rot,
          bold: weightBold,
          underline: isUnderline,
          isReverse: isRev,
          font: o.font,
          align: o.align,
          maxWidth: o.maxWidth,
          baselineOffset: fs * bl,
          svgY: svgY,
          textAnchorX: textAnchorX,
          svgAnchor: anchor,
        );

      case BoxElement():
        final o = el.options;
        final x = o.x.toDouble();
        final y = o.y.toDouble();
        final w = o.width.toDouble();
        final h = o.height.toDouble();
        final t = (o.thickness ?? 1).toDouble();
        final r = (o.radius ?? 0).toDouble();
        final isFilled = t >= min(w, h);

        return PreviewRectItem(
          x: isFilled ? x : x + t / 2.0,
          y: isFilled ? y : y + t / 2.0,
          width: isFilled ? w : max(0.0, w - t),
          height: isFilled ? h : max(0.0, h - t),
          thickness: t,
          radius: r,
          isFilled: isFilled,
          color: PreviewColor.black,
        );

      case LineElement():
        final o = el.options;
        return PreviewLineItem(
          x1: o.x1.toDouble(),
          y1: o.y1.toDouble(),
          x2: o.x2.toDouble(),
          y2: o.y2.toDouble(),
          thickness: (o.thickness ?? 1).toDouble(),
          color: PreviewColor.black,
        );

      case CircleElement():
        final o = el.options;
        final t = (o.thickness ?? 1).toDouble();
        final d = o.diameter.toDouble();
        final r = d / 2.0;
        final isFilled = t >= r;
        final cx = o.x.toDouble() + r;
        final cy = o.y.toDouble() + r;

        return PreviewCircleItem(
          cx: cx,
          cy: cy,
          radius: isFilled ? r : max(0.0, r - t / 2.0),
          thickness: t,
          isFilled: isFilled,
          color: PreviewColor.black,
        );

      case EllipseElement():
        final o = el.options;
        final t = (o.thickness ?? 1).toDouble();
        final w = o.width.toDouble();
        final h = o.height.toDouble();
        final rx = w / 2.0;
        final ry = h / 2.0;

        return PreviewOvalItem(
          cx: o.x.toDouble() + rx,
          cy: o.y.toDouble() + ry,
          rx: rx,
          ry: ry,
          thickness: t,
          color: PreviewColor.black,
        );

      case ReverseElement():
        final o = el.options;
        return PreviewRectItem(
          x: o.x.toDouble(),
          y: o.y.toDouble(),
          width: o.width.toDouble(),
          height: o.height.toDouble(),
          thickness: 0,
          radius: 0,
          isFilled: true,
          color: PreviewColor.black,
        );

      case EraseElement():
        final o = el.options;
        return PreviewRectItem(
          x: o.x.toDouble(),
          y: o.y.toDouble(),
          width: o.width.toDouble(),
          height: o.height.toDouble(),
          thickness: 0,
          radius: 0,
          isFilled: true,
          color: PreviewColor.white,
        );

      case BarcodeElement():
        final o = el.options;
        final x = o.x.toDouble();
        final y = o.y.toDouble();
        final h = o.height.toDouble();
        final rot = o.rotation ?? 0;
        final isReadable = (o.readable ?? 0) != 0;

        final pattern = BarcodeEncoder.encode(o.type, el.content);
        if (pattern != null) {
          final nw = max(1, o.narrow ?? 2).toDouble();
          final textHeight = isReadable ? 14.0 : 0.0;
          final barHeight = max(4.0, h - textHeight);
          final bars = <PreviewBitmapSpan>[];

          var currentX = 0.0;
          for (var i = 0; i < pattern.moduleWidths.length; i++) {
            final w = pattern.moduleWidths[i] * nw;
            final isBar = (i % 2 == 0);
            if (isBar) {
              bars.add(
                PreviewBitmapSpan(
                  y: 0,
                  xStart: currentX.toInt(),
                  pixelCount: w.toInt(),
                  targetX: currentX,
                  targetY: 0,
                  targetWidth: w,
                  targetHeight: barHeight,
                ),
              );
            }
            currentX += w;
          }

          return PreviewBarcodeItem(
            x: x,
            y: y,
            width: currentX,
            height: h,
            rotation: rot,
            symbology: o.type,
            payload: el.content,
            readable: isReadable,
            bars: List.unmodifiable(bars),
          );
        }

        // Fallback placeholder
        final labelText = 'BARCODE: ${el.content}';
        final w = max(100.0, labelText.length * 8.0);
        return PreviewPlaceholderItem(
          x: x,
          y: y,
          width: w,
          height: h,
          rotation: rot,
          kind: PreviewPlaceholderKind.barcode,
          typeName: o.type,
          payload: el.content,
          label: labelText,
        );

      case QRCodeElement():
        final o = el.options;
        final x = o.x.toDouble();
        final y = o.y.toDouble();
        final rot = o.rotation ?? 0;
        final cellW = max(1, o.cellWidth ?? 4);

        final qrMatrix =
            QrCodeEncoder.encode(el.content, ecc: o.eccLevel ?? 'M');
        if (qrMatrix != null) {
          final size = qrMatrix.size;
          final qz = 2; // 2 modules quiet zone
          final totalDim = (size + qz * 2) * cellW.toDouble();
          final modules = <PreviewBitmapSpan>[];

          for (var r = 0; r < size; r++) {
            var c = 0;
            while (c < size) {
              if (qrMatrix.isDark(r, c)) {
                final startC = c;
                while (c < size && qrMatrix.isDark(r, c)) {
                  c++;
                }
                final count = c - startC;
                modules.add(
                  PreviewBitmapSpan(
                    y: r,
                    xStart: startC,
                    pixelCount: count,
                    targetX: (startC + qz) * cellW.toDouble(),
                    targetY: (r + qz) * cellW.toDouble(),
                    targetWidth: count * cellW.toDouble(),
                    targetHeight: cellW.toDouble(),
                  ),
                );
              } else {
                c++;
              }
            }
          }

          return PreviewQrItem(
            x: x,
            y: y,
            width: totalDim,
            height: totalDim,
            rotation: rot,
            payload: el.content,
            moduleSize: cellW,
            matrixSize: size,
            modules: List.unmodifiable(modules),
          );
        }

        // Fallback placeholder
        final placeholderSize = cellW * 20.0;
        return PreviewPlaceholderItem(
          x: x,
          y: y,
          width: placeholderSize,
          height: placeholderSize,
          rotation: rot,
          kind: PreviewPlaceholderKind.qrCode,
          typeName: 'QR',
          payload: el.content,
          label: 'QR:\n${el.content}',
        );

      case ImageElement():
        final o = el.options;
        final x = (o.x ?? 0).toDouble();
        final y = (o.y ?? 0).toDouble();
        final bmp = el.bitmap;
        final w = (o.width ?? bmp.width).toDouble();
        final h = (o.height ?? bmp.height).toDouble();
        final spans = _extractBitmapSpans(bmp, x, y, w, h);

        return PreviewBitmapItem(
          x: x,
          y: y,
          width: w,
          height: h,
          sourceWidth: bmp.width,
          sourceHeight: bmp.height,
          spans: spans,
        );

      case RawElement():
        return null;
    }
  }

  static List<PreviewBitmapSpan> _extractBitmapSpans(
    MonochromeBitmap bmp,
    double destX,
    double destY,
    double destW,
    double destH,
  ) {
    final scaleX = destW / bmp.width;
    final scaleY = destH / bmp.height;
    final spans = <PreviewBitmapSpan>[];
    final data = Uint8List.fromList(bmp.data);
    final bytesPerRow = bmp.bytesPerRow;
    final w = bmp.width;
    final h = bmp.height;

    for (var py = 0; py < h; py++) {
      var px = 0;
      while (px < w) {
        final byteIdx = py * bytesPerRow + (px >> 3);
        if (byteIdx >= data.length) break;
        final bitIdx = 7 - (px & 7);
        final isBlack = (data[byteIdx] >> bitIdx) & 1;

        if (isBlack == 1) {
          final startX = px;
          while (px < w) {
            final nextByteIdx = py * bytesPerRow + (px >> 3);
            if (nextByteIdx >= data.length) break;
            final nextBitIdx = 7 - (px & 7);
            if (((data[nextByteIdx] >> nextBitIdx) & 1) != 1) break;
            px++;
          }
          final count = px - startX;
          spans.add(
            PreviewBitmapSpan(
              y: py,
              xStart: startX,
              pixelCount: count,
              targetX: destX + startX * scaleX,
              targetY: destY + py * scaleY,
              targetWidth: count * scaleX,
              targetHeight: scaleY,
            ),
          );
        } else {
          px++;
        }
      }
    }
    return List.unmodifiable(spans);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PreviewScene || runtimeType != other.runtimeType) {
      return false;
    }
    if (widthDots != other.widthDots ||
        heightDots != other.heightDots ||
        dpi != other.dpi ||
        languageName != other.languageName ||
        items.length != other.items.length) {
      return false;
    }
    for (var i = 0; i < items.length; i++) {
      if (items[i] != other.items[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        widthDots,
        heightDots,
        dpi,
        languageName,
        Object.hashAll(items),
      );
}
