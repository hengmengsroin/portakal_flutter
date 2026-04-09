import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:portakal_flutter/src/builder.dart';
import 'package:portakal_flutter/src/preview.dart';
import 'package:portakal_flutter/src/types.dart';

void main() {
  group('SVG preview renderer', () {
    test('returns valid SVG string', () {
      final svg = renderPreview(label(LabelConfig(width: 40, height: 30)).resolve());
      expect(svg, contains('<svg'));
      expect(svg, contains('</svg>'));
      expect(svg, contains('xmlns="http://www.w3.org/2000/svg"'));
    });

    test('renders label background with correct dimensions', () {
      final svg = renderPreview(label(LabelConfig(width: 40, height: 30)).resolve());
      expect(svg, contains('width="320"'));
      expect(svg, contains('height="240"'));
      expect(svg, contains('320×240 dots'));
      expect(svg, contains('203 DPI'));
    });

    test('renders text element', () {
      final svg = renderPreview(
        label(LabelConfig(width: 40, height: 30)).text('Hello World', TextOptions(x: 10, y: 20, size: 2)).resolve(),
      );
      expect(svg, contains('Hello World'));
      expect(svg, contains('<text'));
    });

    test('escapes XML special characters in text', () {
      final svg = renderPreview(
        label(LabelConfig(width: 40, height: 30)).text('A<B>C&D', TextOptions(x: 10, y: 10)).resolve(),
      );
      expect(svg, contains('A&lt;B&gt;C&amp;D'));
    });

    test('renders bold text with font-weight', () {
      final svg = renderPreview(
        label(LabelConfig(width: 40, height: 30)).text('Bold', TextOptions(x: 10, y: 10, bold: true)).resolve(),
      );
      expect(svg, contains('font-weight="bold"'));
    });

    test('renders reverse text as white (XOR approximation)', () {
      final svg = renderPreview(
        label(LabelConfig(width: 40, height: 30)).text('Reverse', TextOptions(x: 10, y: 10, reverse: true)).resolve(),
      );
      expect(svg, contains('fill="#fff"'));
      expect(svg, contains('Reverse'));
    });

    test('renders box as rect with stroke', () {
      final svg = renderPreview(
        label(LabelConfig(width: 40, height: 30))
            .box(BoxOptions(x: 5, y: 5, width: 100, height: 80, thickness: 2))
            .resolve(),
      );
      expect(svg, contains('fill="none"'));
      expect(svg, contains('stroke="#000"'));
      expect(svg, contains('stroke-width="2"'));
    });

    test('renders line element', () {
      final svg = renderPreview(
        label(LabelConfig(width: 40, height: 30))
            .line(LineOptions(x1: 10, y1: 50, x2: 300, y2: 50, thickness: 2))
            .resolve(),
      );
      expect(svg, contains('<line'));
      expect(svg, contains('x1="10"'));
      expect(svg, contains('stroke-width="2"'));
    });

    test('renders circle element', () {
      final svg = renderPreview(
        label(LabelConfig(width: 40, height: 30))
            .circle(CircleOptions(x: 100, y: 100, diameter: 60, thickness: 2))
            .resolve(),
      );
      expect(svg, contains('<circle'));
      expect(svg, contains('r="29"'));
    });

    test('renders monochrome bitmap image', () {
      final bitmap = MonochromeBitmap(
        data: Uint8List.fromList([0xAA, 0x55]),
        width: 8,
        height: 2,
        bytesPerRow: 1,
      );
      final svg = renderPreview(
        label(LabelConfig(width: 40, height: 30)).image(bitmap, ImageOptions(x: 10, y: 10)).resolve(),
      );
      expect(svg, contains('<rect'));
    });

    test('ignores raw elements in preview', () {
      final svg = renderPreview(label(LabelConfig(width: 40, height: 30)).raw('SET CUTTER ON').resolve());
      expect(svg, isNot(contains('SET CUTTER ON')));
    });
  });
}
