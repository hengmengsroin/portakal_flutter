import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:portakal_flutter/src/lang/cpcl.dart';
import 'package:portakal_flutter/src/lang/dpl.dart';
import 'package:portakal_flutter/src/lang/epl.dart';
import 'package:portakal_flutter/src/lang/escpos.dart';
import 'package:portakal_flutter/src/lang/ipl.dart';
import 'package:portakal_flutter/src/lang/sbpl.dart';
import 'package:portakal_flutter/src/lang/starprnt.dart';
import 'package:portakal_flutter/src/lang/tsc.dart';
import 'package:portakal_flutter/src/lang/zpl.dart';
import 'package:portakal_flutter/src/markup.dart';
import 'package:portakal_flutter/src/preview.dart';

void main() {
  group('markup — HTML-like label DSL', () {
    test('parses basic label with text', () {
      final output = tsc.compile(
        markup('<label width="40mm" height="30mm"><text x="10" y="10" size="2">Hello World</text></label>'),
      );
      expect(output, contains('SIZE 40 mm,30 mm'));
      expect(output, contains('"Hello World"'));
      expect(output, contains('PRINT'));
    });

    test('parses text with bold and underline', () {
      final output = tsc.compile(
        markup('<label width="40mm" height="30mm"><text x="10" y="10" bold underline>Styled Text</text></label>'),
      );
      expect(output, contains('"Styled Text"'));
    });

    test('parses self-closing tags', () {
      final output = tsc.compile(
        markup('<label width="40mm" height="30mm"><line x1="5" y1="50" x2="315" y2="50" thickness="2" /><box x="5" y="5" width="310" height="230" border="2" /><circle x="250" y="150" diameter="60" /></label>'),
      );
      expect(output, contains('BAR'));
      expect(output, contains('BOX'));
      expect(output, contains('CIRCLE'));
    });

    test('parses box with radius', () {
      final output = tsc.compile(
        markup('<label width="40mm" height="30mm"><box x="10" y="10" width="200" height="100" border="2" radius="5" /></label>'),
      );
      expect(output, contains(',5'));
    });

    test('parses ellipse', () {
      final output = tsc.compile(
        markup('<label width="40mm" height="30mm"><ellipse x="50" y="50" width="100" height="60" thickness="2" /></label>'),
      );
      expect(output, contains('ELLIPSE'));
    });

    test('parses reverse and erase', () {
      final output = tsc.compile(
        markup('<label width="40mm" height="30mm"><reverse x="10" y="10" width="200" height="30" /><erase x="50" y="50" width="20" height="20" /></label>'),
      );
      expect(output, contains('REVERSE'));
      expect(output, contains('ERASE'));
    });

    test('compiles to ZPL', () {
      final output = zpl.compile(
        markup('<label width="40mm" height="30mm"><text x="50" y="50" size="2">ZPL Label</text><box x="10" y="10" width="300" height="220" border="2" /></label>'),
      );
      expect(output, contains('^XA'));
      expect(output, contains('^FDZPL Label^FS'));
      expect(output, contains('^GB'));
      expect(output, contains('^XZ'));
    });

    test('compiles to EPL', () {
      final output = epl.compile(
        markup('<label width="40mm" height="30mm"><text x="10" y="10">EPL Label</text></label>'),
      );
      expect(output, contains('N'));
      expect(output, contains('"EPL Label"'));
    });

    test('compiles to ESC/POS', () {
      final output = escpos.compile(
        markup('<label width="80mm"><text align="center" size="2" bold>My Store</text><text>Total: \$29.48</text></label>'),
      );
      expect(output, isA<Uint8List>());
      expect(output.length, greaterThan(10));
    });

    test('compiles to all 9 languages', () {
      final m = markup('<label width="40mm" height="30mm"><text x="10" y="10">Test</text></label>');
      expect(tsc.compile(m), contains('TEXT'));
      expect(zpl.compile(m), contains('^XA'));
      expect(epl.compile(m), contains('N'));
      expect(cpcl.compile(m), contains('PRINT'));
      expect(dpl.compile(m), contains('E'));
      expect(sbpl.compile(m), contains('\x1bA'));
      expect(ipl.compile(m), contains('\x02'));
      expect(escpos.compile(m), isA<Uint8List>());
      expect(starprnt.compile(m), isA<Uint8List>());
    });

    test('renders preview', () {
      final svg = renderPreview(
        markup('<label width="40mm" height="30mm"><text x="10" y="10" size="2">Preview Test</text><box x="5" y="5" width="310" height="230" border="2" /></label>').resolve(),
      );
      expect(svg, contains('<svg'));
      expect(svg, contains('Preview Test'));
    });

    test('uses printer profile', () {
      final resolved = markup('<label printer="tsc-te310" width="40mm" height="30mm"><text x="10" y="10">Profile Test</text></label>').resolve();
      expect(resolved.dpi, equals(300)); // TE310 is 300 DPI
    });

    test('parses label config attributes', () {
      final resolved = markup('<label width="100mm" height="50mm" dpi="300" speed="6" density="12" copies="3"><text x="10" y="10">Config Test</text></label>').resolve();
      expect(resolved.dpi, equals(300));
      expect(resolved.speed, equals(6));
      expect(resolved.density, equals(12));
      expect(resolved.copies, equals(3));
    });

    test('handles multiple text elements', () {
      final output = tsc.compile(
        markup('<label width="40mm" height="30mm"><text x="10" y="10" size="2">Title</text><text x="10" y="35">Subtitle</text><text x="10" y="55" size="1">Description</text></label>'),
      );
      expect(output, contains('"Title"'));
      expect(output, contains('"Subtitle"'));
      expect(output, contains('"Description"'));
    });

    test('handles complex shipping label', () {
      final output = tsc.compile(
        markup('<label width="100mm" height="150mm" dpi="203"><text x="10" y="10" size="2" bold>FROM: Warehouse A</text><text x="10" y="40" size="3" bold>TO: John Doe</text><text x="10" y="80">123 Main St, New York, NY 10001</text><line x1="5" y1="110" x2="780" y2="110" thickness="2" /><box x="5" y="5" width="780" height="1170" border="3" /></label>'),
      );
      expect(output, contains('SIZE 100 mm,150 mm'));
      expect(output, contains('"FROM: Warehouse A"'));
      expect(output, contains('"TO: John Doe"'));
      expect(output, contains('BOX'));
      expect(output, contains('BAR'));
    });

    test('throws on missing <label> root', () {
      expect(() => markup('<text>Hello</text>'), throwsA(isA<ArgumentError>()));
    });

    test('handles raw content', () {
      final output = tsc.compile(
        markup('<label width="40mm" height="30mm"><raw>SET CUTTER ON</raw></label>'),
      );
      expect(output, contains('SET CUTTER ON'));
    });
  });
}
