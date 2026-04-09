import 'package:test/test.dart';
import 'package:portakal_flutter/src/builder.dart';
import 'package:portakal_flutter/src/lang/ipl.dart';
import 'package:portakal_flutter/src/types.dart';

void main() {
  group('IPL compiler', () {
    test('generates format creation and program mode', () {
      final output = ipl.compile(label(LabelConfig(width: 40, height: 30)));
      expect(output, contains('\x02\x1bC1\x03'));
      expect(output, contains('\x02\x1bP\x03'));
    });

    test('generates format end', () {
      final output = ipl.compile(label(LabelConfig(width: 40, height: 30)));
      expect(output, contains('\x02\x1bE1\x03'));
    });

    test('generates print command', () {
      final output = ipl.compile(label(LabelConfig(width: 40, height: 30)));
      expect(output, contains('\x02R\x03'));
    });

    test('generates label size config', () {
      final output = ipl.compile(label(LabelConfig(width: 40, height: 30)));
      expect(output, contains('<SI>L240')); // 30mm at 203 DPI
      expect(output, contains('<SI>W320')); // 40mm at 203 DPI
    });

    test('generates speed and density config', () {
      final output = ipl.compile(label(LabelConfig(width: 40, height: 30, speed: 6, density: 10)));
      expect(output, contains('<SI>S60'));
      expect(output, contains('<SI>d10'));
    });

    test('generates text field (H command)', () {
      final output = ipl.compile(
        label(LabelConfig(width: 40, height: 30))
            .text('Hello IPL', TextOptions(x: 50, y: 30)),
      );
      expect(output, contains('H1;o50,30'));
      expect(output, contains('Hello IPL'));
    });

    test('generates rotated text', () {
      final output = ipl.compile(
        label(LabelConfig(width: 40, height: 30))
            .text('Rotated', TextOptions(x: 10, y: 20, rotation: 90)),
      );
      expect(output, contains(';f1;')); // rotation 1 = 90 degrees
    });

    test('generates box field (W command)', () {
      final output = ipl.compile(
        label(LabelConfig(width: 40, height: 30))
            .box(BoxOptions(x: 10, y: 20, width: 200, height: 100, thickness: 2)),
      );
      expect(output, contains('W1;o10,20'));
      expect(output, contains('l200'));
      expect(output, contains('h100'));
      expect(output, contains('w2'));
    });

    test('generates horizontal line (L command)', () {
      final output = ipl.compile(
        label(LabelConfig(width: 40, height: 30))
            .line(LineOptions(x1: 10, y1: 50, x2: 300, y2: 50, thickness: 2)),
      );
      expect(output, contains('L1;o10,50'));
      expect(output, contains('l290'));
    });

    test('generates vertical line', () {
      final output = ipl.compile(
        label(LabelConfig(width: 40, height: 30))
            .line(LineOptions(x1: 50, y1: 10, x2: 50, y2: 200)),
      );
      expect(output, contains(';f1;')); // vertical
      expect(output, contains('l190'));
    });

    test('generates multiple copies', () {
      final output = ipl.compile(label(LabelConfig(width: 40, height: 30, copies: 5)));
      expect(output, contains('\x1bM5'));
    });

    test('handles raw passthrough', () {
      final output = ipl.compile(label(LabelConfig(width: 40, height: 30)).raw('CUSTOM_CMD'));
      expect(output, contains('CUSTOM_CMD'));
    });
  });
}
