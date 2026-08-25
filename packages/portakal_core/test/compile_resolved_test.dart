import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:portakal_core/portakal_core.dart';

void main() {
  group('CompileResolved & Same-Job Guarantee Tests (All 9 Protocols)', () {
    late MonochromeBitmap testBitmap;

    setUp(() {
      testBitmap = MonochromeBitmap(
        data: Uint8List.fromList([0xFF, 0x00, 0xAA, 0x55]),
        width: 16,
        height: 2,
        bytesPerRow: 2,
      );
    });

    LabelBuilder createStandardJobBuilder() {
      return label(const LabelConfig(width: 50, height: 40, copies: 2))
          .text(
            'Invoice #100',
            const TextOptions(x: 10, y: 10, bold: true, size: 2),
          )
          .box(
            const BoxOptions(x: 5, y: 5, width: 100, height: 80, thickness: 2),
          )
          .line(
            const LineOptions(x1: 10, y1: 40, x2: 200, y2: 40, thickness: 2),
          )
          .circle(
            const CircleOptions(x: 150, y: 50, diameter: 40, thickness: 2),
          )
          .barcode(
            '12345678',
            const BarcodeOptions(x: 10, y: 100, type: '128', height: 40),
          )
          .qrcode(
            'https://portakal.dev',
            const QRCodeOptions(x: 200, y: 100, cellWidth: 4),
          )
          .image(testBitmap, const ImageOptions(x: 10, y: 160))
          .rawBytes(Uint8List.fromList([0x20, 0x20]));
    }

    test(
      'TSC — compile(builder) is byte-identical to compileResolved(job)',
      () {
        final builder = createStandardJobBuilder();
        final job = builder.resolve();

        final bytesFromBuilder = tsc.compile(builder);
        final bytesFromResolved = tsc.compileResolved(job);

        expect(bytesFromResolved, equals(bytesFromBuilder));
        expect(bytesFromResolved.isNotEmpty, isTrue);
      },
    );

    test(
      'ZPL — compile(builder) is byte-identical to compileResolved(job)',
      () {
        final builder = createStandardJobBuilder();
        final job = builder.resolve();

        final bytesFromBuilder = zpl.compile(
          builder,
          policy: UnsupportedFeaturePolicy.ignore,
        );
        final bytesFromResolved = zpl.compileResolved(
          job,
          policy: UnsupportedFeaturePolicy.ignore,
        );

        expect(bytesFromResolved, equals(bytesFromBuilder));
        expect(bytesFromResolved.isNotEmpty, isTrue);
      },
    );

    test(
      'EPL — compile(builder) is byte-identical to compileResolved(job)',
      () {
        final builder = createStandardJobBuilder();
        final job = builder.resolve();

        final bytesFromBuilder = epl.compile(
          builder,
          policy: UnsupportedFeaturePolicy.ignore,
        );
        final bytesFromResolved = epl.compileResolved(
          job,
          policy: UnsupportedFeaturePolicy.ignore,
        );

        expect(bytesFromResolved, equals(bytesFromBuilder));
        expect(bytesFromResolved.isNotEmpty, isTrue);
      },
    );

    test(
      'ESC/POS — compile(builder) is byte-identical to compileResolved(job)',
      () {
        final builder = createStandardJobBuilder();
        final job = builder.resolve();

        final bytesFromBuilder = escpos.compile(
          builder,
          policy: UnsupportedFeaturePolicy.ignore,
        );
        final bytesFromResolved = escpos.compileResolved(
          job,
          policy: UnsupportedFeaturePolicy.ignore,
        );

        expect(bytesFromResolved, equals(bytesFromBuilder));
        expect(bytesFromResolved.isNotEmpty, isTrue);
      },
    );

    test(
      'CPCL — compile(builder) is byte-identical to compileResolved(job)',
      () {
        final builder = createStandardJobBuilder();
        final job = builder.resolve();

        final bytesFromBuilder = cpcl.compile(
          builder,
          policy: UnsupportedFeaturePolicy.ignore,
        );
        final bytesFromResolved = cpcl.compileResolved(
          job,
          policy: UnsupportedFeaturePolicy.ignore,
        );

        expect(bytesFromResolved, equals(bytesFromBuilder));
        expect(bytesFromResolved.isNotEmpty, isTrue);
      },
    );

    test(
      'DPL — compile(builder) is byte-identical to compileResolved(job)',
      () {
        final builder = createStandardJobBuilder();
        final job = builder.resolve();

        final bytesFromBuilder = dpl.compile(
          builder,
          policy: UnsupportedFeaturePolicy.ignore,
        );
        final bytesFromResolved = dpl.compileResolved(
          job,
          policy: UnsupportedFeaturePolicy.ignore,
        );

        expect(bytesFromResolved, equals(bytesFromBuilder));
        expect(bytesFromResolved.isNotEmpty, isTrue);
      },
    );

    test(
      'IPL — compile(builder) is byte-identical to compileResolved(job)',
      () {
        final builder = createStandardJobBuilder();
        final job = builder.resolve();

        final bytesFromBuilder = ipl.compile(
          builder,
          policy: UnsupportedFeaturePolicy.ignore,
        );
        final bytesFromResolved = ipl.compileResolved(
          job,
          policy: UnsupportedFeaturePolicy.ignore,
        );

        expect(bytesFromResolved, equals(bytesFromBuilder));
        expect(bytesFromResolved.isNotEmpty, isTrue);
      },
    );

    test(
      'SBPL — compile(builder) is byte-identical to compileResolved(job)',
      () {
        final builder = createStandardJobBuilder();
        final job = builder.resolve();

        final bytesFromBuilder = sbpl.compile(
          builder,
          policy: UnsupportedFeaturePolicy.ignore,
        );
        final bytesFromResolved = sbpl.compileResolved(
          job,
          policy: UnsupportedFeaturePolicy.ignore,
        );

        expect(bytesFromResolved, equals(bytesFromBuilder));
        expect(bytesFromResolved.isNotEmpty, isTrue);
      },
    );

    test(
      'StarPRNT — compile(builder) is byte-identical to compileResolved(job)',
      () {
        final builder = createStandardJobBuilder();
        final job = builder.resolve();

        final bytesFromBuilder = starprnt.compile(
          builder,
          policy: UnsupportedFeaturePolicy.ignore,
        );
        final bytesFromResolved = starprnt.compileResolved(
          job,
          policy: UnsupportedFeaturePolicy.ignore,
        );

        expect(bytesFromResolved, equals(bytesFromBuilder));
        expect(bytesFromResolved.isNotEmpty, isTrue);
      },
    );

    test('Same-Job & Mutation Isolation Guarantee', () {
      final builder = label(
        const LabelConfig(width: 40, height: 30),
      ).text('Original Header', const TextOptions(x: 10, y: 10));

      // Resolve snapshot
      final resolved = builder.resolve();
      final originalSvg = renderPreview(resolved);
      final originalTsc = tsc.compileResolved(resolved);

      // Mutate builder after resolution
      builder
          .text('Mutated Trailing Text', const TextOptions(x: 50, y: 50))
          .box(const BoxOptions(x: 0, y: 0, width: 20, height: 20))
          .print(5);

      // Verify the previously resolved job was not mutated
      expect(resolved.elements.length, equals(1));
      expect(resolved.copies, equals(1));

      // Verify preview and compiler output for resolved job remains identical
      final postMutationSvg = renderPreview(resolved);
      final postMutationTsc = tsc.compileResolved(resolved);

      expect(postMutationSvg, equals(originalSvg));
      expect(postMutationTsc, equals(originalTsc));

      // Verify new resolve() reflects builder mutations
      final newResolved = builder.resolve();
      expect(newResolved.elements.length, equals(3));
      expect(newResolved.copies, equals(5));
      expect(renderPreview(newResolved), isNot(equals(originalSvg)));
      expect(tsc.compileResolved(newResolved), isNot(equals(originalTsc)));
    });

    test('Policy handling through compileResolved across protocols', () {
      final builder = label(
        const LabelConfig(width: 40, height: 30),
      ).circle(const CircleOptions(x: 10, y: 10, diameter: 20));
      final job = builder.resolve();

      // DPL does not support circle: throw by default, succeed with ignore
      expect(
        () => dpl.compileResolved(
          job,
          policy: UnsupportedFeaturePolicy.throwError,
        ),
        throwsA(isA<UnsupportedFeatureError>()),
      );

      final dplIgnored = dpl.compileResolved(
        job,
        policy: UnsupportedFeaturePolicy.ignore,
      );
      expect(dplIgnored.isNotEmpty, isTrue);
    });

    test(
      'Copies count respected in compileResolved for supported protocols',
      () {
        final builder = label(
          const LabelConfig(width: 40, height: 30),
        ).print(3);
        final job = builder.resolve();

        final tscBytes = tsc.compileResolved(job);
        final tscAscii = String.fromCharCodes(tscBytes);
        expect(tscAscii, contains('PRINT 3\r\n'));
      },
    );
  });
}
