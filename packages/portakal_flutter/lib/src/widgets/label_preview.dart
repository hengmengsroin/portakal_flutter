import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:portakal_core/portakal_core.dart' hide Column;

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
    final scene = PreviewScene.fromBuilder(label);
    final widthDots = scene.widthDots.toDouble();
    final heightDots = scene.heightDots.toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 320.0;
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
                    scene: scene,
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
                    '${scene.widthDots}x${scene.heightDots} dots (${scene.dpi} DPI)',
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
  final PreviewScene scene;
  final Color backgroundColor;
  final Color canvasColor;
  final Color borderColor;

  const _LabelPreviewPainter({
    required this.scene,
    required this.backgroundColor,
    required this.canvasColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final widthDots = scene.widthDots.toDouble();
    final heightDots = scene.heightDots.toDouble();

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
    canvas.clipRect(Rect.fromLTWH(0, 0, widthDots, heightDots));

    for (final item in scene.items) {
      _drawItem(canvas, item);
    }

    canvas.restore();
  }

  void _drawItem(Canvas canvas, PreviewItem item) {
    switch (item) {
      case PreviewTextItem():
        _drawText(canvas, item);
      case PreviewRectItem():
        _drawRect(canvas, item);
      case PreviewLineItem():
        _drawLine(canvas, item);
      case PreviewCircleItem():
        _drawCircle(canvas, item);
      case PreviewOvalItem():
        _drawOval(canvas, item);
      case PreviewPlaceholderItem():
        _drawPlaceholder(canvas, item);
      case PreviewBitmapItem():
        _drawBitmap(canvas, item);
    }
  }

  void _drawText(Canvas canvas, PreviewTextItem item) {
    final color = item.isReverse ? Colors.white : Colors.black;

    final textStyle = TextStyle(
      color: color,
      fontSize: item.fontSize.toDouble(),
      fontWeight: item.bold ? FontWeight.bold : FontWeight.normal,
      decoration:
          item.underline ? TextDecoration.underline : TextDecoration.none,
      fontFamily: item.font == '0' ? null : 'monospace',
    );

    final painter = TextPainter(
      text: TextSpan(text: item.text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: (item.maxWidth ?? double.infinity).toDouble());

    double drawX = item.x;
    if (item.maxWidth != null && item.align == 'center') {
      drawX = item.x + (item.maxWidth! - painter.width) / 2.0;
    } else if (item.maxWidth != null && item.align == 'right') {
      drawX = item.x + item.maxWidth! - painter.width;
    }

    final drawY = item.y;

    if (item.rotation != 0) {
      canvas.save();
      canvas.translate(item.x, item.y);
      canvas.rotate((item.rotation * math.pi) / 180.0);
      painter.paint(canvas, Offset(drawX - item.x, drawY - item.y));
      canvas.restore();
    } else {
      painter.paint(canvas, Offset(drawX, drawY));
    }
  }

  void _drawRect(Canvas canvas, PreviewRectItem item) {
    final color =
        item.color == PreviewColor.white ? Colors.white : Colors.black;
    final rect = Rect.fromLTWH(item.x, item.y, item.width, item.height);

    if (item.radius > 0) {
      final rrect =
          RRect.fromRectAndRadius(rect, Radius.circular(item.radius));
      if (item.isFilled) {
        canvas.drawRRect(rrect, Paint()..color = color);
      } else {
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = item.thickness,
        );
      }
    } else {
      if (item.isFilled) {
        canvas.drawRect(rect, Paint()..color = color);
      } else {
        canvas.drawRect(
          rect,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = item.thickness,
        );
      }
    }
  }

  void _drawLine(Canvas canvas, PreviewLineItem item) {
    final color =
        item.color == PreviewColor.white ? Colors.white : Colors.black;
    canvas.drawLine(
      Offset(item.x1, item.y1),
      Offset(item.x2, item.y2),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = item.thickness,
    );
  }

  void _drawCircle(Canvas canvas, PreviewCircleItem item) {
    final color =
        item.color == PreviewColor.white ? Colors.white : Colors.black;
    final center = Offset(item.cx, item.cy);

    if (item.isFilled) {
      canvas.drawCircle(center, item.radius, Paint()..color = color);
    } else {
      canvas.drawCircle(
        center,
        item.radius,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = item.thickness,
      );
    }
  }

  void _drawOval(Canvas canvas, PreviewOvalItem item) {
    final color =
        item.color == PreviewColor.white ? Colors.white : Colors.black;
    final rect = Rect.fromCenter(
      center: Offset(item.cx, item.cy),
      width: item.rx * 2.0,
      height: item.ry * 2.0,
    );

    canvas.drawOval(
      rect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = item.thickness,
    );
  }

  void _drawPlaceholder(Canvas canvas, PreviewPlaceholderItem item) {
    final isRotated = item.rotation != 0;
    if (isRotated) {
      canvas.save();
      canvas.translate(item.x, item.y);
      canvas.rotate((item.rotation * math.pi) / 180.0);
    }

    final localRect = isRotated
        ? Rect.fromLTWH(0, 0, item.width, item.height)
        : Rect.fromLTWH(item.x, item.y, item.width, item.height);

    canvas.drawRect(localRect, Paint()..color = const Color(0xFFE4E4E7));
    canvas.drawRect(
      localRect,
      Paint()
        ..color = const Color(0xFF71717A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: item.label,
        style: TextStyle(
          color: const Color(0xFF18181B),
          fontSize: item.kind == PreviewPlaceholderKind.barcode ? 10 : 8,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: math.max(1.0, item.width - 8));

    final textOffset = isRotated
        ? Offset(
            4,
            item.kind == PreviewPlaceholderKind.barcode
                ? (item.height - textPainter.height) / 2.0
                : 4,
          )
        : Offset(
            item.x + 4,
            item.kind == PreviewPlaceholderKind.barcode
                ? item.y + (item.height - textPainter.height) / 2.0
                : item.y + 4,
          );

    textPainter.paint(canvas, textOffset);

    if (isRotated) {
      canvas.restore();
    }
  }

  void _drawBitmap(Canvas canvas, PreviewBitmapItem item) {
    final paint = Paint()..color = Colors.black;
    for (final span in item.spans) {
      canvas.drawRect(
        Rect.fromLTWH(
          span.targetX,
          span.targetY,
          span.targetWidth,
          span.targetHeight,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LabelPreviewPainter oldDelegate) {
    return oldDelegate.scene != scene ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.canvasColor != canvasColor ||
        oldDelegate.borderColor != borderColor;
  }
}
