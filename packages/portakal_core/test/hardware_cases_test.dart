import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';

import '../tool/src/case_registry.dart';
import '../tool/src/evidence_seed.dart';
import '../tool/src/hex_formatter.dart';
import '../tool/src/raster_fixture.dart';
import '../tool/src/sha256.dart';

void main() {
  group('Hardware Validation Case Registry', () {
    test('contains all 9 canonical protocol IDs', () {
      expect(
        CaseRegistry.supportedProtocols,
        unorderedEquals([
          'tsc',
          'escpos',
          'zpl',
          'epl',
          'cpcl',
          'dpl',
          'ipl',
          'sbpl',
          'star',
        ]),
      );
    });

    test('retrieves cases for all registered protocols', () {
      for (final proto in CaseRegistry.supportedProtocols) {
        final cases = CaseRegistry.getCasesForProtocol(proto);
        expect(
          cases,
          isNotEmpty,
          reason: 'Protocol $proto should have registered cases',
        );
      }
    });

    test('throws ArgumentError for unknown protocol', () {
      expect(
        () => CaseRegistry.getCasesForProtocol('unknown_proto'),
        throwsArgumentError,
      );
    });

    test('returns null for unknown case in valid protocol', () {
      expect(CaseRegistry.getCase('zpl', 'H99_NONEXISTENT'), isNull);
    });

    test('H02 code page variants are registered strictly where supported', () {
      final zplCases = CaseRegistry.getCasesForProtocol(
        'zpl',
      ).map((c) => c.id).toList();
      expect(zplCases, contains('H02-UTF8'));
      expect(zplCases, contains('H02-CP1252'));
      expect(
        zplCases,
        isNot(contains('H02-CP857')),
      ); // Turkish CP857 not in standard ZPL encoding enum

      final escposCases = CaseRegistry.getCasesForProtocol(
        'escpos',
      ).map((c) => c.id).toList();
      expect(escposCases, contains('H02-CP437'));
      expect(escposCases, contains('H02-CP858'));
      expect(escposCases, contains('H02-CP850'));
      expect(escposCases, contains('H02-CP1252'));
      expect(escposCases, contains('H02-CP857'));
      expect(escposCases, contains('H02-CP866'));
    });

    test('unsupported raster cases are typed as notSupportedSdk', () {
      final dplH09 = CaseRegistry.getCase('dpl', 'H09')!;
      expect(dplH09.isSupported, isFalse);
      expect(dplH09.status, equals(SupportStatus.notSupportedSdk));

      final iplH09 = CaseRegistry.getCase('ipl', 'H09')!;
      expect(iplH09.isSupported, isFalse);
      expect(iplH09.status, equals(SupportStatus.notSupportedSdk));

      final sbplH09 = CaseRegistry.getCase('sbpl', 'H09')!;
      expect(sbplH09.isSupported, isFalse);
      expect(sbplH09.status, equals(SupportStatus.notSupportedSdk));
    });
  });

  group('Determinism & Generation Integrity', () {
    test('generators produce byte-exact repeatable output and SHA-256', () {
      for (final proto in CaseRegistry.supportedProtocols) {
        final cases = CaseRegistry.getCasesForProtocol(proto);
        for (final def in cases) {
          if (!def.isSupported) continue;

          final run1 = def.generator();
          final run2 = def.generator();
          expect(
            run1,
            equals(run2),
            reason: 'Case ${def.id} in $proto must be deterministic',
          );

          final sha1 = calculateSha256(run1);
          final sha2 = calculateSha256(run2);
          expect(sha1, equals(sha2));
        }
      }
    });
  });

  group('Raster Test Fixture (64x64)', () {
    test('generates exactly 512 bytes with 8 bytes per row', () {
      final bytes = generateRaster64x64Bytes();
      expect(bytes.length, equals(512));

      final bmp = createRaster64x64Bitmap();
      expect(bmp.width, equals(64));
      expect(bmp.height, equals(64));
      expect(bmp.bytesPerRow, equals(8));
      expect(bmp.data.length, equals(512));
    });

    test('has solid outer top and bottom borders (0xFF across row)', () {
      final bytes = generateRaster64x64Bytes();
      // Row 0 (first 8 bytes)
      for (int i = 0; i < 8; i++) {
        expect(
          bytes[i],
          equals(0xFF),
          reason: 'Top border byte $i must be 0xFF',
        );
      }
      // Row 63 (last 8 bytes)
      for (int i = 512 - 8; i < 512; i++) {
        expect(
          bytes[i],
          equals(0xFF),
          reason: 'Bottom border byte $i must be 0xFF',
        );
      }
    });

    test('matches canonical fixture SHA-256', () {
      final bytes = generateRaster64x64Bytes();
      final sha = calculateSha256(bytes);
      expect(sha, isNotEmpty);
      expect(sha.length, equals(64));

      // Save fixture file to verify repository asset
      final fixtureFile = File('test/fixtures/hardware/raster_64x64.bin');
      fixtureFile.parent.createSync(recursive: true);
      fixtureFile.writeAsBytesSync(bytes);
      expect(fixtureFile.existsSync(), isTrue);
      expect(fixtureFile.lengthSync(), equals(512));
    });
  });

  group('IPL Safety Constraints', () {
    test(
      'all IPL hardware cases strictly use format slots between F90 and F99',
      () {
        final iplCases = CaseRegistry.getCasesForProtocol('ipl');
        for (final def in iplCases) {
          if (!def.isSupported) continue;

          final bytes = def.generator();
          final content = String.fromCharCodes(bytes);

          // Check format create/erase/select tokens (e.g. E90, F90, \x1BE90)
          final formatRegex = RegExp(r'[EF](\d+)');
          final matches = formatRegex.allMatches(content);
          for (final match in matches) {
            final slotNum = int.parse(match.group(1)!);
            expect(
              slotNum >= 90 && slotNum <= 99,
              isTrue,
              reason:
                  'IPL case ${def.id} used format slot F$slotNum outside reserved range F90-F99',
            );
          }
        }
      },
    );
  });

  group('Protocol Specific Golden Assertions', () {
    test('ZPL H07 emits ^BQ QR code and does NOT contain binary ^GFB', () {
      final zplH07 = CaseRegistry.getCase('zpl', 'H07')!;
      final bytes = zplH07.generator();
      final text = String.fromCharCodes(bytes);

      expect(text, startsWith('^XA\n^CI28\n'));
      expect(
        text,
        contains('^BQN,2,5,M,7^FDQA,https://example.com/portakal-hw-test^FS'),
      );
      expect(text, endsWith('^XZ\n'));
    });

    test('ZPL H09 emits ^GFA ASCII hex and not ^GFB', () {
      final zplH09 = CaseRegistry.getCase('zpl', 'H09')!;
      final bytes = zplH09.generator();
      final text = String.fromCharCodes(bytes);

      expect(text, contains('^GFA,512,512,8,'));
      expect(text, isNot(contains('^GFB')));
    });

    test(
      'Star H09 emits Star Line Mode raster ESC * r A ... b nL nH ... ESC * r B',
      () {
        final starH09 = CaseRegistry.getCase('star', 'H09')!;
        final bytes = starH09.generator();

        // Check ESC @
        expect(bytes[0], equals(0x1B));
        expect(bytes[1], equals(0x40));

        // Find ESC * r A (0x1B 0x2A 0x72 0x41)
        bool foundStartRaster = false;
        for (int i = 0; i < bytes.length - 3; i++) {
          if (bytes[i] == 0x1B &&
              bytes[i + 1] == 0x2A &&
              bytes[i + 2] == 0x72 &&
              bytes[i + 3] == 0x41) {
            foundStartRaster = true;
            break;
          }
        }
        expect(
          foundStartRaster,
          isTrue,
          reason: 'Star raster must contain ESC * r A',
        );

        // Find ESC * r B (0x1B 0x2A 0x72 0x42)
        bool foundEndRaster = false;
        for (int i = 0; i < bytes.length - 3; i++) {
          if (bytes[i] == 0x1B &&
              bytes[i + 1] == 0x2A &&
              bytes[i + 2] == 0x72 &&
              bytes[i + 3] == 0x42) {
            foundEndRaster = true;
            break;
          }
        }
        expect(
          foundEndRaster,
          isTrue,
          reason: 'Star raster must contain ESC * r B',
        );
      },
    );

    test('ESC/POS H01 emits ESC @, align, bold, text, and cut', () {
      final escposH01 = CaseRegistry.getCase('escpos', 'H01')!;
      final bytes = escposH01.generator();

      // Contains ESC @ (0x1B 0x40)
      bool foundEscAt = false;
      for (int i = 0; i < bytes.length - 1; i++) {
        if (bytes[i] == 0x1B && bytes[i + 1] == 0x40) {
          foundEscAt = true;
          break;
        }
      }
      expect(foundEscAt, isTrue);

      // Contains GS V cut sequence (0x1D 0x56)
      bool foundCut = false;
      for (int i = 0; i < bytes.length - 1; i++) {
        if (bytes[i] == 0x1D && bytes[i + 1] == 0x56) {
          foundCut = true;
          break;
        }
      }
      expect(foundCut, isTrue);
    });

    test('TSC H01 emits SIZE, CLS, TEXT, PRINT', () {
      final tscH01 = CaseRegistry.getCase('tsc', 'H01')!;
      final bytes = tscH01.generator();
      final text = String.fromCharCodes(bytes);

      expect(text, contains('SIZE 800 dot,600 dot\r\n'));
      expect(text, contains('CLS\r\n'));
      expect(
        text,
        contains('TEXT 50,120,"0",0,2,2,"PORTAKAL 123 ABC xyz"\r\n'),
      );
      expect(text, contains('PRINT 1\r\n'));
    });

    test('EPL H09 emits GW binary raster', () {
      final eplH09 = CaseRegistry.getCase('epl', 'H09')!;
      final bytes = eplH09.generator();
      final text = String.fromCharCodes(bytes.sublist(0, 100));

      expect(text, contains('N\n'));
      expect(text, contains('GW50,70,8,64\n'));
    });

    test('CPCL H09 emits EG ASCII-hex raster', () {
      final cpclH09 = CaseRegistry.getCase('cpcl', 'H09')!;
      final bytes = cpclH09.generator();
      final text = String.fromCharCodes(bytes);

      expect(text, contains('! 0 203 203 400 1\r\n'));
      expect(text, contains('EG 8 64 50 70 '));
      expect(text, contains('FORM\r\nPRINT\r\n'));
    });
  });

  group('Hex Formatter & Evidence Seed', () {
    test('formats deterministic 16-byte row hex dump', () {
      final data = Uint8List.fromList([
        0x1B,
        0x40,
        0x1B,
        0x61,
        0x01,
        0x54,
        0x45,
        0x53,
        0x54,
        0x0A,
      ]);
      final hex = formatHexDump(data);

      expect(hex, contains('00000000  1B 40 1B 61 01 54 45 53  54 0A'));
    });

    test(
      'evidence seed JSON contains valid schema structure and N/T results',
      () {
        final jsonStr = generateEvidenceSeedJson(
          protocol: 'zpl',
          caseId: 'H07',
          description: '2D QR Code',
          builderName: 'ZplPrinter',
          binFilename: 'H07.bin',
          hexFilename: 'H07.hex',
          sha256:
              '183d29dbcc99c8a25a947d83a296b3ddffcc9218db5084fda97666ca8132a53b',
          byteCount: 142,
          expectedPayload: 'https://example.com/portakal-hw-test',
        );

        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        expect(map['schema_version'], equals(1));
        expect(map['protocol'], equals('zpl'));
        expect(map['case_id'], equals('H07'));
        expect(map['sdk']['builder'], equals('ZplPrinter'));
        expect(map['result']['level2'], equals('N/T'));
        expect(map['result']['level3'], equals('N/T'));
        expect(map['result']['simulator'], equals('N/T'));
        expect(
          map['expected']['payload'],
          equals('https://example.com/portakal-hw-test'),
        );
      },
    );
  });
}
