import 'package:test/test.dart';
import 'package:portakal_flutter/src/builder.dart';
import 'package:portakal_flutter/src/lang/dpl.dart';
import 'package:portakal_flutter/src/types.dart';

void main() {
  group('DPL compiler', () {
    test('generates STX L and E', () {
      final output = dpl.compile(label(LabelConfig(width: 40, height: 30)));
      expect(output, contains('\x02L'));
      expect(output, contains('E'));
    });

    test('generates density', () {
      final output = dpl.compile(label(LabelConfig(width: 40, height: 30, density: 8)));
      expect(output, contains('D08'));
    });

    test('generates speed', () {
      final output = dpl.compile(label(LabelConfig(width: 40, height: 30, speed: 4)));
      expect(output, contains('S04'));
    });

    test('generates width', () {
      final output = dpl.compile(label(LabelConfig(width: 40, height: 30)));
      expect(output, contains('A0320'));
    });

    test('generates copies', () {
      final output = dpl.compile(label(LabelConfig(width: 40, height: 30, copies: 3)));
      expect(output, contains('Q0003'));
    });

    test('generates text record', () {
      final output = dpl.compile(
        label(LabelConfig(width: 40, height: 30))
            .text('Hello DPL', TextOptions(x: 50, y: 30)),
      );
      expect(output, contains('Hello DPL'));
    });

    test('generates raw passthrough', () {
      final output = dpl.compile(
        label(LabelConfig(width: 40, height: 30)).raw('CUSTOM_CMD'),
      );
      expect(output, contains('CUSTOM_CMD'));
    });
  });
}
