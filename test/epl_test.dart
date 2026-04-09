

import 'package:flutter_test/flutter_test.dart';
import 'package:portakal_flutter/src/builder.dart';
import 'package:portakal_flutter/src/lang/epl.dart';
import 'package:portakal_flutter/src/types.dart';

void main() {
  group('EPL compiler', () {
    test('generates N (clear buffer)', () {
      final output = epl.compile(label(LabelConfig(width: 40, height: 30)));
      expect(output, contains('N'));
    });

    test('generates q (width in dots)', () {
      final output = epl.compile(label(LabelConfig(width: 40, height: 30)));
      expect(output, contains('q320'));
    });

    test('generates Q (height and gap)', () {
      final output = epl.compile(label(LabelConfig(width: 40, height: 30)));
      expect(output, contains('Q240,24'));
    });

    test('generates A (text) field', () {
      final output = epl.compile(
        label(LabelConfig(width: 40, height: 30))
            .text('Hello EPL', TextOptions(x: 10, y: 20, font: '3', size: 2)),
      );
      expect(output, contains('"Hello EPL"'));
      expect(output, contains('A10,20,'));
    });

    test('generates X (box) field', () {
      final output = epl.compile(
        label(LabelConfig(width: 40, height: 30))
            .box(BoxOptions(x: 5, y: 5, width: 310, height: 230, thickness: 2)),
      );
      expect(output, contains('X5,5,315,235,2'));
    });

    test('generates LO (line) field', () {
      final output = epl.compile(
        label(LabelConfig(width: 40, height: 30))
            .line(LineOptions(x1: 10, y1: 50, x2: 300, y2: 50, thickness: 2)),
      );
      expect(output, contains('LO10,50,290,2'));
    });

    test('generates P (copies)', () {
      final output = epl.compile(label(LabelConfig(width: 40, height: 30, copies: 3)));
      expect(output, contains('P3'));
    });
  });
}
