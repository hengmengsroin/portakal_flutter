import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:portakal_core/portakal_core.dart' hide Column;

/// Flutter widget that previews a label before printing.
///
/// Supports three construction paths:
/// 1. [LabelPreview.new] — Simple developer experience accepting a mutable [LabelBuilder].
/// 2. [LabelPreview.resolved] — Canonical preview-before-print workflow accepting an immutable [ResolvedLabel].
/// 3. [LabelPreview.scene] — Direct rendering of a canonical [PreviewScene].
class LabelPreview extends StatelessWidget {
  final PreviewScene scene;
  final Color backgroundColor;
  final Color canvasColor;
  final Color borderColor;
  final bool showMeta;
  final BoxFit fit;

  /// Creates a label preview widget from a mutable [LabelBuilder].
  ///
  /// For interactive flows or preview-before-print approval dialogues, prefer
  /// [LabelPreview.resolved] with a pre-resolved [ResolvedLabel] job.
  LabelPreview({
    super.key,
    required LabelBuilder label,
    this.backgroundColor = const Color(0xFFF5F5F4),
    this.canvasColor = Colors.white,
    this.borderColor = const Color(0xFFE5E5E5),
    this.showMeta = true,
    this.fit = BoxFit.contain,
  }) : scene = PreviewScene.fromBuilder(label);

  /// Creates a label preview widget from an immutable [ResolvedLabel] job.
  ///
  /// This guarantees that the exact logical print job displayed in the preview
  /// is identical to the job compiled to printer bytes via `compileResolved(job)`.
  LabelPreview.resolved({
    super.key,
    required ResolvedLabel job,
    this.backgroundColor = const Color(0xFFF5F5F4),
    this.canvasColor = Colors.white,
    this.borderColor = const Color(0xFFE5E5E5),
    this.showMeta = true,
    this.fit = BoxFit.contain,
  }) : scene = PreviewScene.fromResolved(job);

  /// Creates a label preview widget directly from a canonical [PreviewScene].
  const LabelPreview.scene({
    super.key,
    required this.scene,
    this.backgroundColor = const Color(0xFFF5F5F4),
    this.canvasColor = Colors.white,
    this.borderColor = const Color(0xFFE5E5E5),
    this.showMeta = true,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final widthDots = scene.widthDots.toDouble();
    final heightDots = scene.heightDots.toDouble();
    final canvasRatio = widthDots / heightDots;
    final metaHeight = showMeta ? 18.0 : 0.0;

    final widthMm = (widthDots / scene.dpi * 25.4).round();
    final heightMm = (heightDots / scene.dpi * 25.4).round();

    return Semantics(
      label:
          'Print preview, $widthMm by $heightMm millimeters, ${scene.widthDots} by ${scene.heightDots} dots',
      image: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hasFiniteWidth = constraints.maxWidth.isFinite;
          final hasFiniteHeight = constraints.maxHeight.isFinite;

          double targetWidth;
          double targetHeight;

          if (hasFiniteWidth && hasFiniteHeight) {
            final maxCanvasHeight = math.max(
              0.0,
              constraints.maxHeight - metaHeight,
            );
            final widthFromHeight = maxCanvasHeight * canvasRatio;

            if (widthFromHeight <= constraints.maxWidth) {
              targetWidth = widthFromHeight;
              targetHeight = maxCanvasHeight + metaHeight;
            } else {
              targetWidth = constraints.maxWidth;
              targetHeight = (targetWidth / canvasRatio) + metaHeight;
            }
          } else if (hasFiniteWidth) {
            targetWidth = constraints.maxWidth;
            targetHeight = (targetWidth / canvasRatio) + metaHeight;
          } else if (hasFiniteHeight) {
            final maxCanvasHeight = math.max(
              0.0,
              constraints.maxHeight - metaHeight,
            );
            targetHeight = constraints.maxHeight;
            targetWidth = maxCanvasHeight * canvasRatio;
          } else {
            targetWidth = 320.0;
            targetHeight = (320.0 / canvasRatio) + metaHeight;
          }

          return Center(
            child: SizedBox(
              width: targetWidth,
              height: targetHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _LabelPreviewPainter(
                          scene: scene,
                          backgroundColor: backgroundColor,
                          canvasColor: canvasColor,
                          borderColor: borderColor,
                        ),
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
            ),
          );
        },
      ),
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
      case PreviewBarcodeItem():
        _drawBarcode(canvas, item);
      case PreviewQrItem():
        _drawQr(canvas, item);
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

    if (item.rotation != 0 || item.xScale != 1) {
      canvas.save();
      canvas.translate(item.x, item.y);
      if (item.rotation != 0) {
        canvas.rotate((item.rotation * math.pi) / 180.0);
      }
      if (item.xScale != 1) {
        canvas.scale(item.xScale.toDouble(), 1.0);
      }
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

  void _drawBarcode(Canvas canvas, PreviewBarcodeItem item) {
    final isRotated = item.rotation != 0;
    if (isRotated) {
      canvas.save();
      canvas.translate(item.x, item.y);
      canvas.rotate((item.rotation * math.pi) / 180.0);
    }

    final barPaint = Paint()..color = Colors.black;
    for (final bar in item.bars) {
      final rect = isRotated
          ? Rect.fromLTWH(
              bar.targetX,
              bar.targetY,
              bar.targetWidth,
              bar.targetHeight,
            )
          : Rect.fromLTWH(
              item.x + bar.targetX,
              item.y + bar.targetY,
              bar.targetWidth,
              bar.targetHeight,
            );
      canvas.drawRect(rect, barPaint);
    }

    if (item.readable) {
      final painter = TextPainter(
        text: TextSpan(
          text: item.payload,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 10,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final textX = isRotated
          ? (item.width - painter.width) / 2.0
          : item.x + (item.width - painter.width) / 2.0;
      final textY = isRotated
          ? item.height - painter.height
          : item.y + item.height - painter.height;

      painter.paint(canvas, Offset(textX, textY));
    }

    if (isRotated) {
      canvas.restore();
    }
  }

  void _drawQr(Canvas canvas, PreviewQrItem item) {
    final isRotated = item.rotation != 0;
    if (isRotated) {
      canvas.save();
      canvas.translate(item.x, item.y);
      canvas.rotate((item.rotation * math.pi) / 180.0);
    }

    final bgRect = isRotated
        ? Rect.fromLTWH(0, 0, item.width, item.height)
        : Rect.fromLTWH(item.x, item.y, item.width, item.height);
    canvas.drawRect(bgRect, Paint()..color = Colors.white);

    final modulePaint = Paint()..color = Colors.black;
    for (final m in item.modules) {
      final rect = isRotated
          ? Rect.fromLTWH(
              m.targetX,
              m.targetY,
              m.targetWidth,
              m.targetHeight,
            )
          : Rect.fromLTWH(
              item.x + m.targetX,
              item.y + m.targetY,
              m.targetWidth,
              m.targetHeight,
            );
      canvas.drawRect(rect, modulePaint);
    }

    if (isRotated) {
      canvas.restore();
    }
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
