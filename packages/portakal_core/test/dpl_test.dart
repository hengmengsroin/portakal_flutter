import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:portakal_core/src/builder.dart';
import 'package:portakal_core/src/lang/dpl.dart';
import 'package:portakal_core/src/types.dart';

void main() {
  String compile(LabelBuilder b) => latin1.decode(dpl.compile(b));

  group('DPL compiler', () {
    test('dpl.compile returns byte-native Uint8List', () {
      final bytes = dpl.compile(label(LabelConfig(width: 40, height: 30)));
      expect(bytes, isA<Uint8List>());
    });

    test('generates STX L and E', () {
      final output = compile(label(LabelConfig(width: 40, height: 30)));
      expect(output, contains('\x02L'));
      expect(output, contains('E'));
    });

    test('generates density', () {
      final output = compile(
        label(LabelConfig(width: 40, height: 30, density: 8)),
      );
      expect(output, contains('D08'));
    });

    test('generates speed', () {
      final output = compile(
        label(LabelConfig(width: 40, height: 30, speed: 4)),
      );
      expect(output, contains('S04'));
    });

    test('generates width', () {
      final output = compile(label(LabelConfig(width: 40, height: 30)));
      expect(output, contains('A0320'));
    });

    test('generates copies', () {
      final output = compile(
        label(LabelConfig(width: 40, height: 30, copies: 3)),
      );
      expect(output, contains('Q0003'));
    });

    test('generates text record', () {
      final output = compile(
        label(
          LabelConfig(width: 40, height: 30),
        ).text('Hello DPL', TextOptions(x: 50, y: 30)),
      );
      expect(output, contains('Hello DPL'));
    });

    test('generates raw passthrough', () {
      final output = compile(
        label(LabelConfig(width: 40, height: 30)).raw('CUSTOM_CMD'),
      );
      expect(output, contains('CUSTOM_CMD'));
    });
  });
}
