import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:portakal_flutter/src/byte_writer.dart';

void main() {
  group('PrinterByteWriter', () {
    test('empty writer produces empty Uint8List and reports correct state', () {
      final writer = PrinterByteWriter();
      expect(writer.length, equals(0));
      expect(writer.isEmpty, isTrue);
      expect(writer.isNotEmpty, isFalse);

      final bytes = writer.toBytes();
      expect(bytes, isEmpty);
      expect(bytes, isA<Uint8List>());
    });

    test('writes ASCII strings correctly', () {
      final writer = PrinterByteWriter();
      writer.writeAscii('ABC');

      expect(writer.length, equals(3));
      expect(writer.isEmpty, isFalse);
      expect(writer.isNotEmpty, isTrue);
      expect(writer.toBytes(), equals(Uint8List.fromList([0x41, 0x42, 0x43])));
    });

    test('throws ArgumentError on non-ASCII characters in writeAscii', () {
      final writer = PrinterByteWriter();
      expect(() => writer.writeAscii('Hello €'), throwsA(isA<ArgumentError>()));
      expect(() => writer.writeAscii('Café'), throwsA(isA<ArgumentError>()));
      expect(() => writer.writeAscii('你好'), throwsA(isA<ArgumentError>()));
    });

    test('writes control bytes faithfully', () {
      final writer = PrinterByteWriter();
      writer.writeByte(0x00); // NUL
      writer.writeByte(0x0A); // LF
      writer.writeByte(0x0D); // CR
      writer.writeByte(0x1B); // ESC
      writer.writeByte(0x1D); // GS

      expect(
        writer.toBytes(),
        equals(Uint8List.fromList([0x00, 0x0A, 0x0D, 0x1B, 0x1D])),
      );
    });

    test('preserves full byte range 0x00..0xFF without alteration', () {
      final writer = PrinterByteWriter();
      final allBytes = List<int>.generate(256, (i) => i);

      writer.writeBytes(allBytes);

      final result = writer.toBytes();
      expect(result.length, equals(256));
      expect(result, equals(Uint8List.fromList(allBytes)));

      // Validate boundary values explicitly
      expect(result[0x00], equals(0x00));
      expect(result[0x7F], equals(0x7F));
      expect(result[0x80], equals(0x80));
      expect(result[0x81], equals(0x81));
      expect(result[0xFE], equals(0xFE));
      expect(result[0xFF], equals(0xFF));
    });

    test('writes mixed content preserving exact binary order', () {
      final writer = PrinterByteWriter();

      // ASCII header
      writer.writeAscii('BITMAP 0,0,3,1,0,');
      // Binary payload containing high bytes
      writer.writeBytes([0x00, 0xFF, 0x80]);
      // ASCII line ending
      writer.writeAscii('\r\n');

      final expected = <int>[
        ...ascii.encode('BITMAP 0,0,3,1,0,'),
        0x00,
        0xFF,
        0x80,
        0x0D,
        0x0A,
      ];

      final result = writer.toBytes();
      expect(result, equals(Uint8List.fromList(expected)));
      expect(result.length, equals(expected.length));
    });

    test('multiple sequential writes preserve insertion order', () {
      final writer = PrinterByteWriter();

      writer.writeAscii('SIZE 40 mm,30 mm\r\n');
      writer.writeAscii('GAP 3 mm,0 mm\r\n');
      writer.writeAscii('CLS\r\n');
      writer.writeBytes([0x1B, 0x40]); // ESC @

      final expected = <int>[
        ...ascii.encode('SIZE 40 mm,30 mm\r\n'),
        ...ascii.encode('GAP 3 mm,0 mm\r\n'),
        ...ascii.encode('CLS\r\n'),
        0x1B,
        0x40,
      ];

      expect(writer.toBytes(), equals(Uint8List.fromList(expected)));
    });

    test('validates single byte range (<0 or >255 throws RangeError)', () {
      final writer = PrinterByteWriter();

      expect(() => writer.writeByte(-1), throwsA(isA<RangeError>()));
      expect(() => writer.writeByte(256), throwsA(isA<RangeError>()));
      expect(() => writer.writeByte(1000), throwsA(isA<RangeError>()));
    });

    test(
      'validates byte iterable range (out of range values throw RangeError)',
      () {
        final writer = PrinterByteWriter();

        expect(
          () => writer.writeBytes([0, 100, 256, 200]),
          throwsA(isA<RangeError>()),
        );
        expect(
          () => writer.writeBytes([0, -5, 100]),
          throwsA(isA<RangeError>()),
        );
      },
    );

    test('supports writeEncoded with custom encoder', () {
      final writer = PrinterByteWriter();
      writer.writeEncoded('Café', (s) => latin1.encode(s));

      expect(
        writer.toBytes(),
        equals(Uint8List.fromList([0x43, 0x61, 0x66, 0xE9])),
      );
    });

    test('supports writeString with standard Encoding', () {
      final writer = PrinterByteWriter();
      writer.writeString('Hello', encoding: ascii);
      writer.writeString(' 世界', encoding: utf8);

      final expected = <int>[...ascii.encode('Hello'), ...utf8.encode(' 世界')];

      expect(writer.toBytes(), equals(Uint8List.fromList(expected)));
    });

    test('clear resets writer buffer', () {
      final writer = PrinterByteWriter();
      writer.writeAscii('DATA');
      expect(writer.length, equals(4));

      writer.clear();
      expect(writer.length, equals(0));
      expect(writer.isEmpty, isTrue);
      expect(writer.toBytes(), isEmpty);
    });

    test('takeBytes returns accumulated bytes and resets writer', () {
      final writer = PrinterByteWriter();
      writer.writeAscii('TEST');

      final taken = writer.takeBytes();
      expect(taken, equals(Uint8List.fromList([0x54, 0x45, 0x53, 0x54])));
      expect(writer.length, equals(0));
      expect(writer.isEmpty, isTrue);
    });
  });
}
