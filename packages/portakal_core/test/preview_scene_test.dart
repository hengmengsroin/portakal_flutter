import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:portakal_core/portakal_core.dart';

void main() {
  group('PreviewScene Canonical Intermediate Model & Parity Tests', () {
    test('P00 — Empty canvas and continuous height fallback', () {
      final fixed = label(const LabelConfig(width: 40, height: 30)).resolve();
      final sceneFixed = PreviewScene.fromResolved(fixed);
      expect(sceneFixed.widthDots, equals(320));
      expect(sceneFixed.heightDots, equals(240));
      expect(sceneFixed.items, isEmpty);

      final continuous = label(const LabelConfig(width: 40)).resolve();
      final sceneCont = PreviewScene.fromResolved(continuous);
      expect(sceneCont.widthDots, equals(320));
      expect(sceneCont.heightDots, equals(400)); // Canonical 400 dot default
      expect(sceneCont.items, isEmpty);
    });

    test('P01 — Basic text element conversion', () {
      final b = label(const LabelConfig(width: 40, height: 30)).text(
        'Hello Portakal',
        const TextOptions(x: 10, y: 20, size: 2, bold: true, underline: true),
      );
      final scene = PreviewScene.fromResolved(b.resolve());

      expect(scene.items.length, equals(1));
      final item = scene.items.first as PreviewTextItem;
      expect(item.text, equals('Hello Portakal'));
      expect(item.x, equals(10.0));
      expect(item.y, equals(20.0));
      expect(item.fontSize, equals(24));
      expect(item.bold, isTrue);
      expect(item.underline, isTrue);
      expect(item.isReverse, isFalse);
    });

    test('P02 — Rotated & aligned text with xScale', () {
      final b = label(const LabelConfig(width: 50, height: 40)).text(
        'CENTERED',
        const TextOptions(
          x: 10,
          y: 15,
          size: 2,
          rotation: 90,
          align: 'center',
          maxWidth: 200,
          xScale: 2,
          yScale: 3,
        ),
      );
      final scene = PreviewScene.fromResolved(b.resolve());
      final item = scene.items.first as PreviewTextItem;

      expect(item.rotation, equals(90));
      expect(item.align, equals('center'));
      expect(item.maxWidth, equals(200));
      expect(item.textAnchorX, equals(110.0)); // 10 + 200 / 2
      expect(item.svgAnchor, equals('middle'));
      expect(item.xScale, equals(2));
      expect(item.yScale, equals(3));
    });

    test('P03 — Shapes: box and line with thickness deflation', () {
      final b = label(const LabelConfig(width: 40, height: 30))
          .box(
            const BoxOptions(
              x: 10,
              y: 10,
              width: 100,
              height: 80,
              thickness: 4,
              radius: 6,
            ),
          )
          .line(const LineOptions(x1: 5, y1: 5, x2: 50, y2: 50, thickness: 2));
      final scene = PreviewScene.fromResolved(b.resolve());

      expect(scene.items.length, equals(2));
      final box = scene.items[0] as PreviewRectItem;
      expect(box.x, equals(12.0)); // 10 + t/2
      expect(box.y, equals(12.0));
      expect(box.width, equals(96.0)); // 100 - t
      expect(box.height, equals(76.0)); // 80 - t
      expect(box.thickness, equals(4.0));
      expect(box.radius, equals(6.0));
      expect(box.isFilled, isFalse);

      final line = scene.items[1] as PreviewLineItem;
      expect(line.x1, equals(5.0));
      expect(line.y1, equals(5.0));
      expect(line.x2, equals(50.0));
      expect(line.y2, equals(50.0));
      expect(line.thickness, equals(2.0));
    });

    test('P04 — Curves: circle and ellipse', () {
      final b = label(const LabelConfig(width: 40, height: 30))
          .circle(
            const CircleOptions(x: 20, y: 30, diameter: 50, thickness: 4),
          )
          .ellipse(
            const EllipseOptions(
              x: 100,
              y: 50,
              width: 80,
              height: 40,
              thickness: 2,
            ),
          );
      final scene = PreviewScene.fromResolved(b.resolve());

      expect(scene.items.length, equals(2));
      final circle = scene.items[0] as PreviewCircleItem;
      expect(circle.cx, equals(45.0)); // 20 + 25
      expect(circle.cy, equals(55.0)); // 30 + 25
      expect(circle.radius, equals(23.0)); // 25 - 4/2
      expect(circle.thickness, equals(4.0));
      expect(circle.isFilled, isFalse);

      final oval = scene.items[1] as PreviewOvalItem;
      expect(oval.cx, equals(140.0)); // 100 + 40
      expect(oval.cy, equals(70.0)); // 50 + 20
      expect(oval.rx, equals(40.0));
      expect(oval.ry, equals(20.0));
      expect(oval.thickness, equals(2.0));
    });

    test('P05 — Barcode deterministic placeholder geometry', () {
      final b = label(const LabelConfig(width: 40, height: 30)).barcode(
        '987654321',
        const BarcodeOptions(
          x: 15,
          y: 25,
          type: '128',
          height: 60,
          rotation: 90,
        ),
      );
      final scene = PreviewScene.fromResolved(b.resolve());

      final item = scene.items.first as PreviewPlaceholderItem;
      expect(item.kind, equals(PreviewPlaceholderKind.barcode));
      expect(item.x, equals(15.0));
      expect(item.y, equals(25.0));
      expect(item.height, equals(60.0));
      expect(item.rotation, equals(90));
      expect(item.label, equals('BARCODE: 987654321'));
      expect(item.width, greaterThanOrEqualTo(100.0));

      final svg = renderPreviewScene(scene);
      expect(svg, contains('BARCODE: 987654321'));
      expect(svg, contains('stroke-dasharray="3,3"'));
      expect(svg, contains('transform="rotate(90 15 25)"'));
    });

    test('P06 — QR code deterministic placeholder geometry', () {
      final b = label(const LabelConfig(width: 40, height: 30)).qrcode(
        'https://portakal.dev',
        const QRCodeOptions(x: 50, y: 50, cellWidth: 5, rotation: 180),
      );
      final scene = PreviewScene.fromResolved(b.resolve());

      final item = scene.items.first as PreviewPlaceholderItem;
      expect(item.kind, equals(PreviewPlaceholderKind.qrCode));
      expect(item.x, equals(50.0));
      expect(item.y, equals(50.0));
      expect(item.width, equals(100.0)); // 5 * 20
      expect(item.height, equals(100.0));
      expect(item.rotation, equals(180));
      expect(item.label, contains('QR:'));

      final svg = renderPreviewScene(scene);
      expect(svg, contains('QR:'));
      expect(svg, contains('https://portakal.dev'));
      expect(svg, contains('transform="rotate(180 50 50)"'));
    });

    test('P07 — Bitmap spans generation without lossy downsampling', () {
      // 8x2 bitmap: row 0: 0b11110000 (0xF0), row 1: 0b00001111 (0x0F)
      final bmp = MonochromeBitmap(
        data: Uint8List.fromList([0xF0, 0x0F]),
        width: 8,
        height: 2,
        bytesPerRow: 1,
      );
      final b = label(const LabelConfig(width: 40, height: 30)).image(
        bmp,
        const ImageOptions(x: 10, y: 20, width: 80, height: 20),
      );
      final scene = PreviewScene.fromResolved(b.resolve());

      final item = scene.items.first as PreviewBitmapItem;
      expect(item.spans.length, equals(2));

      // Row 0: 4 pixels from x=0 to 3
      final span0 = item.spans[0];
      expect(span0.y, equals(0));
      expect(span0.xStart, equals(0));
      expect(span0.pixelCount, equals(4));
      expect(span0.targetX, equals(10.0));
      expect(span0.targetY, equals(20.0));
      expect(span0.targetWidth, equals(40.0)); // 4 * (80/8)
      expect(span0.targetHeight, equals(10.0)); // 20/2

      // Row 1: 4 pixels from x=4 to 7
      final span1 = item.spans[1];
      expect(span1.y, equals(1));
      expect(span1.xStart, equals(4));
      expect(span1.pixelCount, equals(4));
      expect(span1.targetX, equals(50.0)); // 10 + 4 * 10
      expect(span1.targetY, equals(30.0)); // 20 + 1 * 10
      expect(span1.targetWidth, equals(40.0));
      expect(span1.targetHeight, equals(10.0));
    });

    test('P08 — Paint order sequential determinism', () {
      final b = label(const LabelConfig(width: 40, height: 30))
          .text('First')
          .box(const BoxOptions(x: 0, y: 0, width: 10, height: 10))
          .erase(const EraseOptions(x: 2, y: 2, width: 5, height: 5))
          .text('Last');
      final scene = PreviewScene.fromResolved(b.resolve());

      expect(scene.items.length, equals(4));
      expect(scene.items[0], isA<PreviewTextItem>());
      expect((scene.items[0] as PreviewTextItem).text, equals('First'));
      expect(scene.items[1], isA<PreviewRectItem>());
      expect(scene.items[2], isA<PreviewRectItem>());
      expect(
        (scene.items[2] as PreviewRectItem).color,
        equals(PreviewColor.white),
      );
      expect(scene.items[3], isA<PreviewTextItem>());
      expect((scene.items[3] as PreviewTextItem).text, equals('Last'));
    });

    test('P09 — Reverse and erase regions', () {
      final b = label(const LabelConfig(width: 40, height: 30))
          .reverse(const ReverseOptions(x: 10, y: 10, width: 50, height: 30))
          .erase(const EraseOptions(x: 20, y: 20, width: 20, height: 10));
      final scene = PreviewScene.fromResolved(b.resolve());

      final rev = scene.items[0] as PreviewRectItem;
      expect(rev.isFilled, isTrue);
      expect(rev.color, equals(PreviewColor.black));

      final era = scene.items[1] as PreviewRectItem;
      expect(era.isFilled, isTrue);
      expect(era.color, equals(PreviewColor.white));
    });

    test('P12 — Unicode & special character escaping in SVG', () {
      final b = label(
        const LabelConfig(width: 40, height: 30),
      ).text('Price: €15.00 & 100% <Safe>', const TextOptions(x: 5, y: 5));
      final scene = PreviewScene.fromResolved(b.resolve());
      final svg = renderPreviewScene(scene);

      expect(svg, contains('Price: €15.00 &amp; 100% &lt;Safe&gt;'));
    });

    test('P14 — Unit & DPI conversion to canonical dots', () {
      final mm203 = label(
        const LabelConfig(width: 40, height: 30, unit: Unit.mm, dpi: 203),
      ).resolve();
      final sceneMm203 = PreviewScene.fromResolved(mm203);
      expect(sceneMm203.widthDots, equals(320));
      expect(sceneMm203.heightDots, equals(240));

      final inch300 = label(
        const LabelConfig(width: 2, height: 1, unit: Unit.inch, dpi: 300),
      ).resolve();
      final sceneInch300 = PreviewScene.fromResolved(inch300);
      expect(sceneInch300.widthDots, equals(600));
      expect(sceneInch300.heightDots, equals(300));
    });

    test('Structural value equality on PreviewScene', () {
      final b1 = label(const LabelConfig(width: 40, height: 30))
          .text('Identical', const TextOptions(x: 10, y: 10))
          .box(const BoxOptions(x: 5, y: 5, width: 20, height: 20));

      final b2 = label(const LabelConfig(width: 40, height: 30))
          .text('Identical', const TextOptions(x: 10, y: 10))
          .box(const BoxOptions(x: 5, y: 5, width: 20, height: 20));

      final scene1 = PreviewScene.fromBuilder(b1);
      final scene2 = PreviewScene.fromBuilder(b2);

      expect(scene1, equals(scene2));
      expect(scene1.hashCode, equals(scene2.hashCode));
    });
  });
}
