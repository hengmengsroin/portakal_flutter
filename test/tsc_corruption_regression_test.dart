import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:portakal_flutter/src/builder.dart';
import 'package:portakal_flutter/src/languages/tsc.dart';
import 'package:portakal_flutter/src/types.dart';

void main() {
  test('Demonstrate string-to-UTF8 corruption of TSC BITMAP payload', () {
    // 1. Original 7-byte test payload containing full range boundaries:
    // 0x00, 0x01, 0x7F (max 7-bit ASCII), 0x80 (first 8-bit non-ASCII), 0x81, 0xFE, 0xFF (max 8-bit byte)
    final rawBytes = Uint8List.fromList([
      0x00,
      0x01,
      0x7F,
      0x80,
      0x81,
      0xFE,
      0xFF,
    ]);
    expect(rawBytes.length, equals(7));

    // 2. Wrap in MonochromeBitmap (7 bytes per row, 1 row = 7 bytes total)
    final bitmap = MonochromeBitmap(
      data: rawBytes,
      width: 56, // 7 bytes * 8 bits
      height: 1,
      bytesPerRow: 7,
    );

    // 3. Compile using existing string-based compileToTSC
    final labelConfig = LabelConfig(width: 40, height: 30);
    final resolved = label(
      labelConfig,
    ).image(bitmap, const ImageOptions(x: 0, y: 0)).resolve();
    final String tscString = compileToTSC(resolved);

    // 4. Inspect what String.fromCharCode did to the high bytes:
    // In Dart VM, String stores UTF-16 code units.
    expect(tscString, contains('BITMAP 0,0,7,1,0,'));

    // 5. When transmitted over typical network socket/transport using UTF-8:
    final utf8Bytes = Uint8List.fromList(utf8.encode(tscString));

    // Find the offset where bitmap payload starts
    final headerAscii = ascii.encode('BITMAP 0,0,7,1,0,');
    final headerIndex = _indexOfSublist(utf8Bytes, headerAscii);
    expect(headerIndex, isNot(equals(-1)));

    final payloadStartIndex = headerIndex + headerAscii.length;
    // Extract the transmitted bitmap portion
    // The original payload was 7 bytes.
    // In UTF-8, each byte >= 0x80 expands into 2 bytes!
    // 0x80 -> 0xC2 0x80
    // 0x81 -> 0xC2 0x81
    // 0xFE -> 0xC3 0xBE
    // 0xFF -> 0xC3 0xBF
    // Total transmitted bytes for the 7-byte payload becomes: 1 + 1 + 1 + 2 + 2 + 2 + 2 = 11 bytes!
    final transmittedPayloadInUtf8 = utf8Bytes.sublist(
      payloadStartIndex,
      payloadStartIndex + 11,
    );

    final expectedCorruptedBytes = [
      0x00,
      0x01,
      0x7F,
      0xC2, 0x80, // corrupted 0x80
      0xC2, 0x81, // corrupted 0x81
      0xC3, 0xBE, // corrupted 0xFE
      0xC3, 0xBF, // corrupted 0xFF
    ];

    expect(transmittedPayloadInUtf8, equals(expectedCorruptedBytes));
    expect(
      transmittedPayloadInUtf8.length,
      equals(11),
      reason: 'Payload expanded from 7 to 11 bytes',
    );
    expect(
      transmittedPayloadInUtf8,
      isNot(equals(rawBytes)),
      reason: 'Binary bitmap payload is corrupted by UTF-8 encoding',
    );
  });
}

int _indexOfSublist(List<int> source, List<int> target) {
  if (target.isEmpty) return 0;
  for (int i = 0; i <= source.length - target.length; i++) {
    bool match = true;
    for (int j = 0; j < target.length; j++) {
      if (source[i + j] != target[j]) {
        match = false;
        break;
      }
    }
    if (match) return i;
  }
  return -1;
}
