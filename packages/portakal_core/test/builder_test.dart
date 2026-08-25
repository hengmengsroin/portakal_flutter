import 'package:test/test.dart';
import 'package:portakal_core/src/builder.dart';
import 'package:portakal_core/src/errors.dart';
import 'package:portakal_core/src/types.dart';

void main() {
  group('label()', () {
    test('creates a LabelBuilder', () {
      final builder = label(LabelConfig(width: 40, height: 30));
      expect(builder, isA<LabelBuilder>());
    });

    test('throws on invalid width', () {
      expect(
        () => label(LabelConfig(width: 0)),
        throwsA(isA<InvalidConfigError>()),
      );
      expect(
        () => label(LabelConfig(width: -1)),
        throwsA(isA<InvalidConfigError>()),
      );
    });
  });

  group('LabelBuilder', () {
    test('chains fluently', () {
      final builder = label(LabelConfig(width: 40, height: 30));
      final result = builder
          .text('Hello')
          .box(BoxOptions(x: 0, y: 0, width: 100, height: 100))
          .line(LineOptions(x1: 0, y1: 0, x2: 100, y2: 100))
          .raw('CUSTOM');

      expect(result, same(builder));
    });

    test('resolves with correct defaults', () {
      final resolved = label(LabelConfig(width: 40, height: 30)).resolve();
      expect(resolved.dpi, equals(203));
      expect(resolved.speed, equals(4));
      expect(resolved.density, equals(8));
      expect(resolved.direction, equals(0));
      expect(resolved.copies, equals(1));
      expect(resolved.widthDots, equals(320));
      expect(resolved.heightDots, equals(240));
    });

    test('resolves with custom config', () {
      final resolved = label(
        LabelConfig(
          width: 4,
          height: 6,
          unit: Unit.inch,
          dpi: 300,
          speed: 6,
          density: 12,
          copies: 3,
        ),
      ).resolve();

      expect(resolved.widthDots, equals(1200));
      expect(resolved.heightDots, equals(1800));
      expect(resolved.dpi, equals(300));
      expect(resolved.speed, equals(6));
      expect(resolved.density, equals(12));
      expect(resolved.copies, equals(3));
    });

    test('resolves height 0 for receipt mode', () {
      final resolved = label(LabelConfig(width: 80)).resolve();
      expect(resolved.heightDots, equals(0));
    });

    test('collects elements in order', () {
      final resolved = label(
        LabelConfig(width: 40, height: 30),
      ).text('First').text('Last').resolve();

      expect(resolved.elements, hasLength(2));
      expect(resolved.elements[0].type, equals('text'));
      expect(resolved.elements[1].type, equals('text'));
    });
  });
}
