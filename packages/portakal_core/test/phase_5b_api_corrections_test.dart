import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:portakal_core/portakal_core.dart';

void main() {
  group('Phase 5B — 1. Receipt Column Naming Collision Resolution', () {
    test('ReceiptColumn is canonical and formats table row correctly', () {
      final col1 = const ReceiptColumn(width: 20, align: 'left');
      final col2 = const ReceiptColumn(width: 12, align: 'right');
      expect(col1.width, equals(20));
      expect(col1.align, equals('left'));
      expect(col2.width, equals(12));
      expect(col2.align, equals('right'));

      final row = formatRow([col1, col2], ['Item', 'Price'], 32);
      expect(row, equals('Item                       Price'));
    });

    test('Deprecated Column typedef aliases ReceiptColumn', () {
      // ignore: deprecated_member_use_from_same_package
      final col = const Column(width: 10);
      expect(col, isA<ReceiptColumn>());
      expect(col.width, equals(10));
      expect(col.align, equals('left'));
    });
  });

  group('Phase 5B — 2. LabelBuilder.print(copies) & Copies Precedence', () {
    test('print(copies) sets copies on ResolvedLabel', () {
      final resolved = label(
        const LabelConfig(width: 40, height: 30),
      ).print(3).resolve();
      expect(resolved.copies, equals(3));
    });

    test('print(copies) takes precedence over LabelConfig.copies', () {
      final resolved = label(
        const LabelConfig(width: 40, height: 30, copies: 2),
      ).print(7).resolve();
      expect(resolved.copies, equals(7));
    });

    test('LabelConfig.copies is respected when print() is not called', () {
      final resolved = label(
        const LabelConfig(width: 40, height: 30, copies: 4),
      ).resolve();
      expect(resolved.copies, equals(4));
    });

    test('Default copies is 1 when neither is specified', () {
      final resolved = label(
        const LabelConfig(width: 40, height: 30),
      ).resolve();
      expect(resolved.copies, equals(1));
    });

    test('print(0) and print(-1) throw InvalidConfigError immediately', () {
      expect(
        () => label(const LabelConfig(width: 40, height: 30)).print(0),
        throwsA(isA<InvalidConfigError>()),
      );
      expect(
        () => label(const LabelConfig(width: 40, height: 30)).print(-5),
        throwsA(isA<InvalidConfigError>()),
      );
    });
  });

  group('Phase 5B — 3. Canonical Compiler Byte API & Aliases', () {
    final sampleLabel = label(
      const LabelConfig(width: 40, height: 30),
    ).text('Canonical Test', const TextOptions(x: 10, y: 10));

    test('All 9 language facades return Uint8List from compile()', () {
      expect(tsc.compile(sampleLabel), isA<Uint8List>());
      expect(zpl.compile(sampleLabel), isA<Uint8List>());
      expect(epl.compile(sampleLabel), isA<Uint8List>());
      expect(cpcl.compile(sampleLabel), isA<Uint8List>());
      expect(dpl.compile(sampleLabel), isA<Uint8List>());
      expect(ipl.compile(sampleLabel), isA<Uint8List>());
      expect(sbpl.compile(sampleLabel), isA<Uint8List>());
      expect(escpos.compile(sampleLabel), isA<Uint8List>());
      expect(starprnt.compile(sampleLabel), isA<Uint8List>());
    });

    test(
      'Deprecated compileBytes() returns byte-for-byte identical output for all 9 facades',
      () {
        // ignore: deprecated_member_use_from_same_package
        expect(tsc.compileBytes(sampleLabel), equals(tsc.compile(sampleLabel)));
        // ignore: deprecated_member_use_from_same_package
        expect(zpl.compileBytes(sampleLabel), equals(zpl.compile(sampleLabel)));
        // ignore: deprecated_member_use_from_same_package
        expect(epl.compileBytes(sampleLabel), equals(epl.compile(sampleLabel)));
        // ignore: deprecated_member_use_from_same_package
        expect(
          cpcl.compileBytes(sampleLabel),
          equals(cpcl.compile(sampleLabel)),
        );
        // ignore: deprecated_member_use_from_same_package
        expect(dpl.compileBytes(sampleLabel), equals(dpl.compile(sampleLabel)));
        // ignore: deprecated_member_use_from_same_package
        expect(ipl.compileBytes(sampleLabel), equals(ipl.compile(sampleLabel)));
        // ignore: deprecated_member_use_from_same_package
        expect(
          sbpl.compileBytes(sampleLabel),
          equals(sbpl.compile(sampleLabel)),
        );
        // ignore: deprecated_member_use_from_same_package
        expect(
          escpos.compileBytes(sampleLabel),
          equals(escpos.compile(sampleLabel)),
        );
        // ignore: deprecated_member_use_from_same_package
        expect(
          starprnt.compileBytes(sampleLabel),
          equals(starprnt.compile(sampleLabel)),
        );
      },
    );

    test(
      'Deprecated String compatibility serializers decode byte-stream correctly',
      () {
        final resolved = sampleLabel.resolve();
        // ignore: deprecated_member_use_from_same_package
        expect(
          compileToTSC(resolved),
          equals(utf8.decode(tsc.compile(sampleLabel))),
        );
        // ignore: deprecated_member_use_from_same_package
        expect(
          compileToZPL(resolved),
          equals(utf8.decode(zpl.compile(sampleLabel))),
        );
        // ignore: deprecated_member_use_from_same_package
        expect(
          compileToEPL(resolved),
          equals(latin1.decode(epl.compile(sampleLabel))),
        );
        // ignore: deprecated_member_use_from_same_package
        expect(
          compileToCPCL(resolved),
          equals(latin1.decode(cpcl.compile(sampleLabel))),
        );
        // ignore: deprecated_member_use_from_same_package
        expect(
          compileToDPL(resolved),
          equals(latin1.decode(dpl.compile(sampleLabel))),
        );
        // ignore: deprecated_member_use_from_same_package
        expect(
          compileToIPL(resolved),
          equals(latin1.decode(ipl.compile(sampleLabel))),
        );
        // ignore: deprecated_member_use_from_same_package
        expect(
          compileToSBPL(resolved),
          equals(latin1.decode(sbpl.compile(sampleLabel))),
        );
      },
    );
  });

  group('Phase 5B — 4. UnsupportedFeaturePolicy Enforcement', () {
    final labelWithCircle = label(const LabelConfig(width: 40, height: 30))
        .text('Circle Test', const TextOptions(x: 10, y: 10))
        .circle(const CircleOptions(x: 20, y: 20, diameter: 10));

    final labelWithEllipse = label(const LabelConfig(width: 40, height: 30))
        .text('Ellipse Test', const TextOptions(x: 10, y: 10))
        .ellipse(const EllipseOptions(x: 20, y: 20, width: 30, height: 20));

    test(
      'ESC/POS throws UnsupportedFeatureError by default on CircleElement',
      () {
        expect(
          () => escpos.compile(labelWithCircle),
          throwsA(isA<UnsupportedFeatureError>()),
        );
      },
    );

    test('ESC/POS omits CircleElement cleanly when policy is ignore', () {
      final bytes = escpos.compile(
        labelWithCircle,
        policy: UnsupportedFeaturePolicy.ignore,
      );
      expect(bytes, isA<Uint8List>());
      expect(bytes.isNotEmpty, isTrue);
    });

    test(
      'Star PRNT throws UnsupportedFeatureError by default on CircleElement',
      () {
        expect(
          () => starprnt.compile(labelWithCircle),
          throwsA(isA<UnsupportedFeatureError>()),
        );
      },
    );

    test('Star PRNT omits CircleElement cleanly when policy is ignore', () {
      final bytes = starprnt.compile(
        labelWithCircle,
        policy: UnsupportedFeaturePolicy.ignore,
      );
      expect(bytes, isA<Uint8List>());
      expect(bytes.isNotEmpty, isTrue);
    });

    test(
      'DPL throws on unsupported EllipseElement by default and ignores cleanly',
      () {
        expect(
          () => dpl.compile(labelWithEllipse),
          throwsA(isA<UnsupportedFeatureError>()),
        );
        final bytes = dpl.compile(
          labelWithEllipse,
          policy: UnsupportedFeaturePolicy.ignore,
        );
        expect(bytes, isA<Uint8List>());
      },
    );

    test(
      'IPL throws on unsupported EllipseElement by default and ignores cleanly',
      () {
        expect(
          () => ipl.compile(labelWithEllipse),
          throwsA(isA<UnsupportedFeatureError>()),
        );
        final bytes = ipl.compile(
          labelWithEllipse,
          policy: UnsupportedFeaturePolicy.ignore,
        );
        expect(bytes, isA<Uint8List>());
      },
    );

    test(
      'SBPL throws on unsupported EllipseElement by default and ignores cleanly',
      () {
        expect(
          () => sbpl.compile(labelWithEllipse),
          throwsA(isA<UnsupportedFeatureError>()),
        );
        final bytes = sbpl.compile(
          labelWithEllipse,
          policy: UnsupportedFeaturePolicy.ignore,
        );
        expect(bytes, isA<Uint8List>());
      },
    );

    test('ResolvedLabel and LabelBuilder.resolve() have no policy state', () {
      final resolved = labelWithCircle.resolve();
      expect(resolved, isA<ResolvedLabel>());
      // ResolvedLabel is purely immutable AST container
      expect(resolved.elements.length, equals(2));
    });
  });

  group('Phase 5B — 5. Error Hierarchy Consistency', () {
    test(
      'UnsupportedCharacterException extends EncodingError extends PortakalError',
      () {
        final ex = UnsupportedCharacterException(
          character: '€',
          codePoint: 0x20AC,
          codePage: PrinterCodePage.cp437,
        );

        expect(ex, isA<EncodingError>());
        expect(ex, isA<PortakalError>());
        expect(ex, isA<Exception>());
        expect(ex.message, contains('U+20AC'));
        expect(ex.character, equals('€'));
        expect(ex.codePoint, equals(0x20AC));
        expect(ex.codePage, equals(PrinterCodePage.cp437));
      },
    );

    test(
      'Catching PortakalError catches UnsupportedCharacterException without duplicate message fields',
      () {
        try {
          throw UnsupportedCharacterException(
            character: 'ÿ',
            codePoint: 0xFF,
            codePage: PrinterCodePage.cp437,
          );
        } on PortakalError catch (e) {
          expect(e.message, contains('cannot be encoded'));
          expect(e.toString(), contains('U+00FF'));
        }
      },
    );

    test('Catching EncodingError catches encoding errors specifically', () {
      try {
        throw UnsupportedCharacterException(
          character: '漢',
          codePoint: 0x6F22,
          codePage: PrinterCodePage.cp437,
        );
      } on EncodingError catch (e) {
        expect(e.message, contains('U+6F22'));
      }
    });
  });

  group('Phase 5B — 6. Universal Raw-Data API Safety & Immutability', () {
    test('RawElement.bytes defensively copies input list', () {
      final originalList = Uint8List.fromList([0x10, 0x20, 0x30]);
      final elem = RawElement.bytes(originalList);

      // Mutating originalList must NOT mutate elem.bytes
      originalList[0] = 0xFF;
      expect(elem.bytes[0], equals(0x10));
      expect(elem.bytes, equals(Uint8List.fromList([0x10, 0x20, 0x30])));
    });

    test('LabelBuilder.rawBytes() defensively copies input list', () {
      final originalList = Uint8List.fromList([0x01, 0x02, 0x03]);
      final builder = label(
        const LabelConfig(width: 40, height: 30),
      ).rawBytes(originalList);

      originalList[0] = 0x99;
      final resolved = builder.resolve();
      final rawElem = resolved.elements.first as RawElement;
      expect(rawElem.bytes[0], equals(0x01));
    });

    test(
      'RawElement.ascii validates ASCII and creates defensive byte array',
      () {
        final elem = RawElement.ascii('ABC~^123');
        expect(
          elem.bytes,
          equals(
            Uint8List.fromList([
              0x41,
              0x42,
              0x43,
              0x7E,
              0x5E,
              0x31,
              0x32,
              0x33,
            ]),
          ),
        );
      },
    );

    test(
      'RawElement.ascii throws UnsupportedCharacterException on non-ASCII',
      () {
        expect(
          () => RawElement.ascii('Café'),
          throwsA(
            isA<UnsupportedCharacterException>()
                .having((e) => e.character, 'character', 'é')
                .having((e) => e.codePoint, 'codePoint', 0xE9),
          ),
        );

        expect(
          () => RawElement.ascii('Price: €10'),
          throwsA(isA<UnsupportedCharacterException>()),
        );
      },
    );

    test(
      'LabelBuilder.rawAscii throws UnsupportedCharacterException on non-ASCII',
      () {
        expect(
          () => label(
            const LabelConfig(width: 40, height: 30),
          ).rawAscii('Hello 🌍'),
          throwsA(isA<UnsupportedCharacterException>()),
        );
      },
    );

    test(
      'Full 0x00..0xFF binary gamut survives exact raw-byte compilation across serializers',
      () {
        final fullGamut = Uint8List.fromList(List<int>.generate(256, (i) => i));
        final builder = label(
          const LabelConfig(width: 40, height: 30),
        ).rawBytes(fullGamut);

        bool containsSequence(Uint8List output, Uint8List seq) {
          final outList = output.toList();
          final seqList = seq.toList();
          for (int i = 0; i <= outList.length - seqList.length; i++) {
            bool match = true;
            for (int j = 0; j < seqList.length; j++) {
              if (outList[i + j] != seqList[j]) {
                match = false;
                break;
              }
            }
            if (match) return true;
          }
          return false;
        }

        // Verify across ESC/POS, TSC, ZPL, Star PRNT
        final escposBytes = escpos.compile(builder);
        expect(containsSequence(escposBytes, fullGamut), isTrue);

        final tscBytes = tsc.compile(builder);
        expect(containsSequence(tscBytes, fullGamut), isTrue);

        final zplBytes = zpl.compile(builder);
        expect(containsSequence(zplBytes, fullGamut), isTrue);

        final starBytes = starprnt.compile(builder);
        expect(containsSequence(starBytes, fullGamut), isTrue);
      },
    );

    test('Deprecated raw(Object) handles String and byte arrays', () {
      // ignore: deprecated_member_use_from_same_package
      final elemStr = RawElement(content: 'TEST');
      expect(
        elemStr.bytes,
        equals(Uint8List.fromList([0x54, 0x45, 0x53, 0x54])),
      );

      // ignore: deprecated_member_use_from_same_package
      final elemBytes = RawElement(content: [1, 2, 3]);
      expect(elemBytes.bytes, equals(Uint8List.fromList([1, 2, 3])));

      // ignore: deprecated_member_use_from_same_package
      final builder = label(
        const LabelConfig(width: 40, height: 30),
      ).raw('LEGACY_RAW');
      final resolved = builder.resolve();
      expect(
        (resolved.elements.first as RawElement).bytes,
        equals(Uint8List.fromList(ascii.encode('LEGACY_RAW'))),
      );
    });
  });

  group('Phase 5B — 7. Legacy Encoding Deprecations', () {
    test('Deprecated legacy encoding helpers remain functional for 1.x', () {
      // ignore: deprecated_member_use_from_same_package
      expect(isASCII('Hello 123'), isTrue);
      // ignore: deprecated_member_use_from_same_package
      expect(isASCII('Café'), isFalse);

      // ignore: deprecated_member_use_from_same_package
      final segs = encodeText('Hello');
      expect(segs.length, equals(1));
      expect(
        segs.first.data,
        equals(Uint8List.fromList([0x48, 0x65, 0x6C, 0x6C, 0x6F])),
      );

      // ignore: deprecated_member_use_from_same_package
      final printerBytes = encodeTextForPrinter('Hello');
      expect(
        printerBytes,
        equals(Uint8List.fromList([0x48, 0x65, 0x6C, 0x6C, 0x6F])),
      );
    });
  });
}
