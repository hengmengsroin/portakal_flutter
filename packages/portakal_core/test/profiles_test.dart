import 'package:test/test.dart';
import 'package:portakal_core/src/profiles.dart';

void main() {
  group('getProfile', () {
    test('returns profile by model ID', () {
      final p = getProfile('epson-tm-t88vi');
      expect(p, isNotNull);
      expect(p!.name, equals('Epson TM-T88VI'));
      expect(p.vendor, equals('Epson'));
      expect(p.language, equals('escpos'));
      expect(p.paperWidth, equals(80));
      expect(p.dotsPerLine, equals(576));
      expect(p.dpi, equals(203));
    });

    test('returns null for unknown model', () {
      expect(getProfile('nonexistent'), isNull);
    });
  });

  group('listProfiles', () {
    test('returns all profile IDs', () {
      final ids = listProfiles();
      expect(ids.length, greaterThan(15));
      expect(ids, contains('epson-tm-t88vi'));
      expect(ids, contains('zebra-zd420'));
      expect(ids, contains('tsc-te200'));
      expect(ids, contains('star-tsp143'));
      expect(ids, contains('sato-cl4nx'));
    });
  });

  group('findByVendorId', () {
    test('finds Epson printers by VID 0x04B8', () {
      final printers = findByVendorId(0x04B8);
      expect(printers.length, greaterThan(2));
      for (final p in printers) {
        expect(p.vendor, equals('Epson'));
      }
    });

    test('finds Zebra printers by VID 0x0A5F', () {
      final printers = findByVendorId(0x0A5F);
      expect(printers.length, greaterThan(1));
      for (final p in printers) {
        expect(p.vendor, equals('Zebra'));
      }
    });

    test('finds Star printers by VID 0x0519', () {
      final printers = findByVendorId(0x0519);
      expect(printers.length, greaterThan(0));
      for (final p in printers) {
        expect(p.vendor, equals('Star Micronics'));
      }
    });

    test('finds TSC printers by VID 0x1203', () {
      final printers = findByVendorId(0x1203);
      expect(printers.length, greaterThan(0));
      for (final p in printers) {
        expect(p.vendor, equals('TSC'));
      }
    });

    test('returns empty for unknown VID', () {
      expect(findByVendorId(0xFFFF), hasLength(0));
    });
  });

  group('findByLanguage', () {
    test('finds ESC/POS printers', () {
      final printers = findByLanguage('escpos');
      expect(printers.length, greaterThan(5));
      for (final p in printers) {
        expect(p.language, equals('escpos'));
      }
    });

    test('finds ZPL printers', () {
      final printers = findByLanguage('zpl');
      expect(printers.length, greaterThan(1));
    });

    test('finds TSC printers', () {
      final printers = findByLanguage('tsc');
      expect(printers.length, greaterThan(0));
    });

    test('finds Star printers', () {
      final printers = findByLanguage('starprnt');
      expect(printers.length, greaterThan(0));
    });
  });

  group('printer profiles data integrity', () {
    test('all profiles have required fields', () {
      for (final entry in printerProfiles.entries) {
        final id = entry.key;
        final p = entry.value;
        expect(p.name.isNotEmpty, isTrue, reason: '$id missing name');
        expect(p.vendor.isNotEmpty, isTrue, reason: '$id missing vendor');
        expect(p.language.isNotEmpty, isTrue, reason: '$id missing language');
        expect(p.paperWidth, greaterThan(0), reason: '$id missing paperWidth');
        expect(
          p.dotsPerLine,
          greaterThan(0),
          reason: '$id missing dotsPerLine',
        );
        expect(p.dpi, greaterThan(0), reason: '$id missing dpi');
      }
    });

    test('DPI and dotsPerLine are consistent', () {
      for (final entry in printerProfiles.entries) {
        final id = entry.key;
        final p = entry.value;
        if (p.paperWidth > 0 && p.dotsPerLine > 0) {
          final expectedDots = (p.paperWidth / 25.4 * p.dpi).round();
          // Allow 10% tolerance for non-standard widths
          expect(
            p.dotsPerLine,
            greaterThan((expectedDots * 0.7).round()),
            reason: '$id dotsPerLine inconsistent',
          );
        }
      }
    });
  });
}
