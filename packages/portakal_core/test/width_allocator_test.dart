import 'package:test/test.dart';
import 'package:portakal_core/portakal_core.dart';
import 'package:portakal_core/src/layout_types.dart';

void main() {
  group('LayoutGeometry.allocateColumns', () {
    test('single flex column receives full available width', () {
      final result = LayoutGeometry.allocateColumns(
        startX: 20,
        availableWidth: 600,
        gap: 0,
        specs: [(fixedWidth: null, flex: 1)],
      );

      expect(result.length, equals(1));
      expect(result[0].x, equals(20));
      expect(result[0].width, equals(600));
    });

    test('single fixed column receives configured fixed width', () {
      final result = LayoutGeometry.allocateColumns(
        startX: 10,
        availableWidth: 500,
        gap: 0,
        specs: [(fixedWidth: 120, flex: null)],
      );

      expect(result.length, equals(1));
      expect(result[0].x, equals(10));
      expect(result[0].width, equals(120));
    });

    test('all-flex columns allocate proportionally without gaps', () {
      final result = LayoutGeometry.allocateColumns(
        startX: 0,
        availableWidth: 600,
        gap: 0,
        specs: [
          (fixedWidth: null, flex: 3),
          (fixedWidth: null, flex: 1),
        ],
      );

      expect(result.length, equals(2));
      expect(result[0], equals((x: 0, width: 450)));
      expect(result[1], equals((x: 450, width: 150)));
      expect(result[0].width + result[1].width, equals(600));
    });

    test('all-fixed columns place sequentially with exact widths', () {
      final result = LayoutGeometry.allocateColumns(
        startX: 15,
        availableWidth: 600,
        gap: 10,
        specs: [
          (fixedWidth: 100, flex: null),
          (fixedWidth: 200, flex: null),
        ],
      );

      expect(result.length, equals(2));
      expect(result[0], equals((x: 15, width: 100)));
      expect(result[1], equals((x: 125, width: 200)));
    });

    test('mixed fixed and flex columns calculate correct positions and widths', () {
      final result = LayoutGeometry.allocateColumns(
        startX: 20,
        availableWidth: 600,
        gap: 8,
        specs: [
          (fixedWidth: null, flex: 1),
          (fixedWidth: 80, flex: null),
          (fixedWidth: null, flex: 1),
        ],
      );

      // totalGaps = 2 * 8 = 16
      // usableWidth = 600 - 16 = 584
      // flexPool = 584 - 80 = 504
      // totalFlex = 2 -> each flex = 252
      expect(result.length, equals(3));
      expect(result[0], equals((x: 20, width: 252)));
      expect(result[1], equals((x: 20 + 252 + 8, width: 80))); // x = 280
      expect(result[2], equals((x: 280 + 80 + 8, width: 252))); // x = 368
      expect(252 + 80 + 252 + 16, equals(600));
    });

    test('last flex column receives remainder when fixed column appears in middle', () {
      final result = LayoutGeometry.allocateColumns(
        startX: 0,
        availableWidth: 101,
        gap: 0,
        specs: [
          (fixedWidth: null, flex: 1),
          (fixedWidth: 20, flex: null),
          (fixedWidth: null, flex: 1),
        ],
      );

      // flexPool = 101 - 20 = 81
      // totalFlex = 2
      // first flex: (1 * 81) ~/ 2 = 40
      // second flex (last flex): 81 - 40 = 41
      expect(result.length, equals(3));
      expect(result[0], equals((x: 0, width: 40)));
      expect(result[1], equals((x: 40, width: 20)));
      expect(result[2], equals((x: 60, width: 41)));
      expect(result[0].width + result[1].width + result[2].width, equals(101));
    });

    test('last flex column receives remainder when fixed column appears at the end', () {
      final result = LayoutGeometry.allocateColumns(
        startX: 0,
        availableWidth: 100,
        gap: 0,
        specs: [
          (fixedWidth: null, flex: 3),
          (fixedWidth: null, flex: 1),
          (fixedWidth: 20, flex: null),
        ],
      );

      // flexPool = 100 - 20 = 80
      // totalFlex = 4
      // first flex: (3 * 80) ~/ 4 = 60
      // second flex: 80 - 60 = 20
      // fixed: 20
      expect(result.length, equals(3));
      expect(result[0], equals((x: 0, width: 60)));
      expect(result[1], equals((x: 60, width: 20)));
      expect(result[2], equals((x: 80, width: 20)));
      expect(result[0].width + result[1].width + result[2].width, equals(100));
    });

    test('gaps are preserved between adjacent columns', () {
      final result = LayoutGeometry.allocateColumns(
        startX: 10,
        availableWidth: 310,
        gap: 10,
        specs: [
          (fixedWidth: null, flex: 1),
          (fixedWidth: null, flex: 1),
          (fixedWidth: null, flex: 1),
        ],
      );

      // totalGaps = 2 * 10 = 20
      // usableWidth = 310 - 20 = 290
      // flex 1: 290 ~/ 3 = 96
      // flex 2: 290 ~/ 3 = 96
      // flex 3: 290 - 192 = 98
      expect(result[0], equals((x: 10, width: 96)));
      expect(result[1], equals((x: 10 + 96 + 10, width: 96))); // 116
      expect(result[2], equals((x: 116 + 96 + 10, width: 98))); // 222
      expect(96 + 96 + 98 + 20, equals(310));
    });

    group('validation errors', () {
      test('throws InvalidConfigError when specs list is empty', () {
        expect(
          () => LayoutGeometry.allocateColumns(
            startX: 0,
            availableWidth: 500,
            gap: 0,
            specs: [],
          ),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('throws InvalidConfigError when availableWidth <= 0', () {
        expect(
          () => LayoutGeometry.allocateColumns(
            startX: 0,
            availableWidth: 0,
            gap: 0,
            specs: [(fixedWidth: 100, flex: null)],
          ),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('throws InvalidConfigError when gap < 0', () {
        expect(
          () => LayoutGeometry.allocateColumns(
            startX: 0,
            availableWidth: 500,
            gap: -1,
            specs: [(fixedWidth: 100, flex: null)],
          ),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('throws InvalidConfigError when fixed width <= 0', () {
        expect(
          () => LayoutGeometry.allocateColumns(
            startX: 0,
            availableWidth: 500,
            gap: 0,
            specs: [(fixedWidth: 0, flex: null)],
          ),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('throws InvalidConfigError when flex weight <= 0', () {
        expect(
          () => LayoutGeometry.allocateColumns(
            startX: 0,
            availableWidth: 500,
            gap: 0,
            specs: [(fixedWidth: null, flex: 0)],
          ),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('throws InvalidConfigError when total gaps exceed availableWidth', () {
        expect(
          () => LayoutGeometry.allocateColumns(
            startX: 0,
            availableWidth: 30,
            gap: 20,
            specs: [
              (fixedWidth: null, flex: 1),
              (fixedWidth: null, flex: 1),
              (fixedWidth: null, flex: 1),
            ],
          ),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('throws InvalidConfigError when fixed widths exceed availableWidth', () {
        expect(
          () => LayoutGeometry.allocateColumns(
            startX: 0,
            availableWidth: 100,
            gap: 10,
            specs: [
              (fixedWidth: 60, flex: null),
              (fixedWidth: 60, flex: null),
            ],
          ),
          throwsA(isA<InvalidConfigError>()),
        );
      });
    });
  });
}
