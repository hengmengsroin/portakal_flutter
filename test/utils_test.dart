import 'package:flutter_test/flutter_test.dart';
import 'package:portakal_flutter/src/utils.dart';
import 'package:portakal_flutter/src/types.dart';

void main() {
  group('toDots', () {
    test('converts mm to dots at 203 DPI', () {
      expect(toDots(25.4, Unit.mm, 203), equals(203));
      expect(toDots(1, Unit.mm, 203), equals(8));
      expect(toDots(40, Unit.mm, 203), equals(320));
      expect(toDots(30, Unit.mm, 203), equals(240));
      expect(toDots(0, Unit.mm, 203), equals(0));
    });

    test('converts mm to dots at 300 DPI', () {
      expect(toDots(25.4, Unit.mm, 300), equals(300));
      expect(toDots(1, Unit.mm, 300), equals(12));
      expect(toDots(40, Unit.mm, 300), equals(472));
    });

    test('converts inches to dots', () {
      expect(toDots(1, Unit.inch, 203), equals(203));
      expect(toDots(4, Unit.inch, 203), equals(812));
      expect(toDots(2, Unit.inch, 300), equals(600));
    });

    test('passes dots through unchanged', () {
      expect(toDots(100, Unit.dot, 203), equals(100));
      expect(toDots(576, Unit.dot, 300), equals(576));
    });

    test('rounds to nearest integer', () {
      expect(toDots(10, Unit.mm, 203), equals(80));
      expect(toDots(3, Unit.mm, 203), equals(24));
    });
  });
}
