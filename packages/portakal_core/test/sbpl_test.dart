import 'dart:convert';
import 'dart:typed_data';

import 'package:portakal_core/src/builder.dart';
import 'package:portakal_core/src/errors.dart';
import 'package:portakal_core/src/lang/sbpl.dart';
import 'package:portakal_core/src/types.dart';
import 'package:test/test.dart';

void main() {
  String compile(LabelBuilder b) => latin1.decode(sbpl.compile(b));

  group('SBPL compiler', () {
    test('sbpl.compile returns byte-native Uint8List', () {
      final bytes = sbpl.compile(
        label(const LabelConfig(width: 40, height: 30)),
      );
      expect(bytes, isA<Uint8List>());
    });

    test('generates ESC A start and ESC Z end', () {
      final output = compile(label(const LabelConfig(width: 40, height: 30)));
      expect(output, contains('\x1bA'));
      expect(output, contains('\x1bZ'));
    });

    test('generates ESC CS (print speed) when speed > 0', () {
      final output = compile(
        label(const LabelConfig(width: 40, height: 30, speed: 4)),
      );
      expect(output, contains('\x1bCS4'));
    });

    test('generates text with position and font', () {
      final output = compile(
        label(
          const LabelConfig(width: 40, height: 30),
        ).text('Hello SATO', const TextOptions(x: 100, y: 50, size: 2)),
      );
      expect(output, contains('\x1bH0100')); // H position
      expect(output, contains('\x1bV0050')); // V position
      expect(output, contains('\x1bL0202')); // magnification 2x2
      expect(output, contains('\x1bK9BHello SATO')); // text output
    });

    test('generates rotated text', () {
      final output = compile(
        label(
          const LabelConfig(width: 40, height: 30),
        ).text('Rotated', const TextOptions(x: 10, y: 20, rotation: 90)),
      );
      expect(output, contains('\x1b%1')); // 90 degree rotation
    });

    test('generates box with FW command', () {
      final output = compile(
        label(const LabelConfig(width: 40, height: 30)).box(
          const BoxOptions(x: 10, y: 20, width: 200, height: 100, thickness: 2),
        ),
      );
      expect(output, contains('\x1bH0010'));
      expect(output, contains('\x1bV0020'));
      expect(output, contains('\x1bFW02V0100H0200'));
    });

    test('generates horizontal line', () {
      final output = compile(
        label(const LabelConfig(width: 40, height: 30)).line(
          const LineOptions(x1: 10, y1: 50, x2: 300, y2: 50, thickness: 2),
        ),
      );
      expect(output, contains('\x1bFW02H0290'));
    });

    test('generates vertical line', () {
      final output = compile(
        label(const LabelConfig(width: 40, height: 30)).line(
          const LineOptions(x1: 50, y1: 10, x2: 50, y2: 200, thickness: 1),
        ),
      );
      expect(output, contains('\x1bFW01V0190'));
    });

    test('throws UnsupportedFeatureError for ImageElement', () {
      final bitmap = MonochromeBitmap(
        data: Uint8List.fromList([0xFF, 0x00]),
        width: 8,
        height: 2,
        bytesPerRow: 1,
      );
      expect(
        () => sbpl.compile(
          label(
            const LabelConfig(width: 40, height: 30),
          ).image(bitmap, const ImageOptions(x: 10, y: 10)),
        ),
        throwsA(isA<UnsupportedFeatureError>()),
      );
    });

    test('generates copies with ESC Q', () {
      final output = compile(
        label(const LabelConfig(width: 40, height: 30, copies: 3)),
      );
      expect(output, contains('\x1bQ3'));
    });

    test('omits ESC Q for single copy', () {
      final output = compile(
        label(const LabelConfig(width: 40, height: 30, copies: 1)),
      );
      expect(output, isNot(contains('\x1bQ')));
    });

    test('handles raw passthrough', () {
      final output = compile(
        label(const LabelConfig(width: 40, height: 30)).raw('\x1bKC1'),
      );
      expect(output, contains('\x1bKC1'));
    });
  });
}
