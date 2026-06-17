import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../builder.dart';
import '../types.dart';

/// Flutter widget that previews a [LabelBuilder] before printing.
class LabelPreview extends StatelessWidget {
  final LabelBuilder label;
  final Color backgroundColor;
  final Color canvasColor;
  final Color borderColor;
  final bool showMeta;

  const LabelPreview({
    super.key,
    required this.label,
    this.backgroundColor = const Color(0xFFF5F5F4),
    this.canvasColor = Colors.white,
    this.borderColor = const Color(0xFFE5E5E5),
    this.showMeta = true,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = label.resolve();
    final widthDots = resolved.widthDots;
    final heightDots = resolved.heightDots > 0 ? resolved.heightDots : 400;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 320.0;
        final ratio = widthDots / heightDots;
        final height = maxWidth / ratio;

        return SizedBox(
          width: maxWidth,
          height: height + (showMeta ? 18 : 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: CustomPaint(
                  painter: _LabelPreviewPainter(
                    label: resolved,
                    backgroundColor: backgroundColor,
                    canvasColor: canvasColor,
                    borderColor: borderColor,
                  ),
                ),
              ),
              if (showMeta)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${resolved.widthDots}x$heightDots dots (${resolved.dpi} DPI)',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFA1A1AA),
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _LabelPreviewPainter extends CustomPainter {
  final ResolvedLabel label;
  final Color backgroundColor;
  final Color canvasColor;
  final Color borderColor;

  const _LabelPreviewPainter({
    required this.label,
    required this.backgroundColor,
    required this.canvasColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final widthDots = label.widthDots.toDouble();
    final heightDots = (label.heightDots > 0 ? label.heightDots : 400)
        .toDouble();

    final bgPaint = Paint()..color = backgroundColor;
    final labelPaint = Paint()..color = canvasColor;
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRect(Offset.zero & size, bgPaint);
    canvas.drawRect(Offset.zero & size, labelPaint);
    canvas.drawRect(Offset.zero & size, borderPaint);

    final sx = size.width / widthDots;
    final sy = size.height / heightDots;

    canvas.save();
    canvas.scale(sx, sy);

    for (final el in label.elements) {
      _drawElement(canvas, el);
    }

    canvas.restore();
  }

  void _drawElement(Canvas canvas, LabelElement el) {
    switch (el) {
      case TextElement():
        _drawText(canvas, el);
      case ImageElement():
        _drawImage(canvas, el);
      case BoxElement():
        _drawBox(canvas, el);
      case LineElement():
        _drawLine(canvas, el);
      case CircleElement():
        _drawCircle(canvas, el);
      case EllipseElement():
        _drawEllipse(canvas, el);
      case BarcodeElement():
        _drawBarcode(canvas, el);
      case QRCodeElement():
        _drawQRCode(canvas, el);
      case ReverseElement():
        final o = el.options;
        canvas.drawRect(
          Rect.fromLTWH(
            o.x.toDouble(),
            o.y.toDouble(),
            o.width.toDouble(),
            o.height.toDouble(),
          ),
          Paint()..color = Colors.black,
        );
      case EraseElement():
        final o = el.options;
        canvas.drawRect(
          Rect.fromLTWH(
            o.x.toDouble(),
            o.y.toDouble(),
            o.width.toDouble(),
            o.height.toDouble(),
          ),
          Paint()..color = Colors.white,
        );
      case RawElement():
        break;
    }
  }

  void _drawText(Canvas canvas, TextElement el) {
    final o = el.options;
    final x = (o.x ?? 0).toDouble();
    final y = (o.y ?? 0).toDouble();
    final fs = _calcFontSize(o.size, o.yScale).toDouble();
    final color = o.reverse == true ? Colors.white : Colors.black;

    final textStyle = TextStyle(
      color: color,
      fontSize: fs,
      fontWeight: o.bold == true ? FontWeight.bold : FontWeight.normal,
      decoration: o.underline == true
          ? TextDecoration.underline
          : TextDecoration.none,
      fontFamily: o.font == '0' ? null : 'monospace',
    );

    final painter = TextPainter(
      text: TextSpan(text: el.content, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: (o.maxWidth ?? double.infinity).toDouble());

    double drawX = x;
    if (o.maxWidth != null && o.align == 'center') {
      drawX = x + (o.maxWidth! - painter.width) / 2;
    } else if (o.maxWidth != null && o.align == 'right') {
      drawX = x + o.maxWidth! - painter.width;
    }

    final drawY = y + fs * _baselineRatio(o.font) - painter.height;

    if ((o.rotation ?? 0) != 0) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((o.rotation! * math.pi) / 180);
      painter.paint(canvas, Offset(drawX - x, drawY - y));
      canvas.restore();
    } else {
      painter.paint(canvas, Offset(drawX, drawY));
    }
  }

  void _drawImage(Canvas canvas, ImageElement el) {
    final o = el.options;
    final x = (o.x ?? 0).toDouble();
    final y = (o.y ?? 0).toDouble();
    final bmp = el.bitmap;
    final targetW = (o.width ?? bmp.width).toDouble();
    final targetH = (o.height ?? bmp.height).toDouble();
    final scaleX = targetW / bmp.width;
    final scaleY = targetH / bmp.height;

    final p = Paint()..color = Colors.black;
    for (var py = 0; py < bmp.height; py++) {
      for (var px = 0; px < bmp.width; px++) {
        final byteIdx = py * bmp.bytesPerRow + (px ~/ 8);
        final bitIdx = 7 - (px % 8);
        final isBlack = (bmp.data[byteIdx] >> bitIdx) & 1;
        if (isBlack == 1) {
          canvas.drawRect(
            Rect.fromLTWH(
              x + px * scaleX,
              y + py * scaleY,
              math.max(1, scaleX),
              math.max(1, scaleY),
            ),
            p,
          );
        }
      }
    }
  }

  void _drawBox(Canvas canvas, BoxElement el) {
    final o = el.options;
    final t = (o.thickness ?? 1).toDouble();
    final rect = Rect.fromLTWH(
      o.x.toDouble(),
      o.y.toDouble(),
      o.width.toDouble(),
      o.height.toDouble(),
    );
    final radius = Radius.circular((o.radius ?? 0).toDouble());

    if (t >= math.min(o.width, o.height)) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, radius),
        Paint()..color = Colors.black,
      );
      return;
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(t / 2), radius),
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = t,
    );
  }

  void _drawLine(Canvas canvas, LineElement el) {
    final o = el.options;
    final t = (o.thickness ?? 1).toDouble();
    canvas.drawLine(
      Offset(o.x1.toDouble(), o.y1.toDouble()),
      Offset(o.x2.toDouble(), o.y2.toDouble()),
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = t,
    );
  }

  void _drawCircle(Canvas canvas, CircleElement el) {
    final o = el.options;
    final t = (o.thickness ?? 1).toDouble();
    final r = o.diameter / 2.0;
    final center = Offset(o.x + r, o.y + r);

    if (t >= r) {
      canvas.drawCircle(center, r, Paint()..color = Colors.black);
      return;
    }

    canvas.drawCircle(
      center,
      math.max(0, r - t / 2),
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = t,
    );
  }

  void _drawEllipse(Canvas canvas, EllipseElement el) {
    final o = el.options;
    final t = (o.thickness ?? 1).toDouble();
    final rect = Rect.fromLTWH(
      o.x.toDouble(),
      o.y.toDouble(),
      o.width.toDouble(),
      o.height.toDouble(),
    );
    canvas.drawOval(
      rect,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = t,
    );
  }

  void _drawBarcode(Canvas canvas, BarcodeElement el) {
    final o = el.options;
    final x = o.x.toDouble();
    final y = o.y.toDouble();
    final h = o.height.toDouble();
    final text = 'BARCODE: ${el.content}';

    // Approximate width for placeholder
    final w = math.max(100.0, text.length * 8.0);
    final rect = Rect.fromLTWH(x, y, w, h);

    canvas.drawRect(rect, Paint()..color = Colors.grey.withValues(alpha: 0.3));
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 10,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w);

    textPainter.paint(canvas, Offset(x + 4, y + (h - textPainter.height) / 2));
  }

  void _drawQRCode(Canvas canvas, QRCodeElement el) {
    final o = el.options;
    final x = o.x.toDouble();
    final y = o.y.toDouble();
    // Approximate size for placeholder based on cell width
    final size = (o.cellWidth ?? 4) * 20.0;
    final rect = Rect.fromLTWH(x, y, size, size);

    canvas.drawRect(rect, Paint()..color = Colors.grey.withValues(alpha: 0.3));
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'QR:\n${el.content}',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 8,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size - 4);

    textPainter.paint(canvas, Offset(x + 2, y + 2));
  }

  int _calcFontSize(int? size, int? yScale) {
    if (yScale != null && yScale > 10) return yScale;
    return math.max(8, (size ?? 1) * 12);
  }

  double _baselineRatio(String? font) => font == '0' ? 0.78 : 0.82;

  @override
  bool shouldRepaint(covariant _LabelPreviewPainter oldDelegate) {
    return oldDelegate.label != label ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.canvasColor != canvasColor ||
        oldDelegate.borderColor != borderColor;
  }
}
