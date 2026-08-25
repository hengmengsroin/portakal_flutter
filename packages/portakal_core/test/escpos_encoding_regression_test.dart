import 'package:test/test.dart';

void main() {
  group('ESC/POS .codeUnits defect proof', () {
    test('Western European: "é" and "€" are corrupted by .codeUnits', () {
      // "é" in Unicode is U+00E9 (233).
      // In CP437, "é" is byte 0x82 (130).
      // In CP858/CP850, "é" is byte 0x82 (130).
      // But String.codeUnits yields [0x00E9].
      // When sent to a CP437 printer, byte 0xE9 renders as 'Θ' (Greek Theta) instead of 'é'!
      const textE = 'é';
      expect(textE.codeUnits, equals([0x00E9]));
      expect(textE.codeUnits.first, isNot(equals(0x82)));

      // "€" in Unicode is U+20AC (8364).
      // In CP858, "€" is byte 0xD5 (213).
      // In CP1252, "€" is byte 0x80 (128).
      // But String.codeUnits yields [0x20AC].
      // Truncated to 8-bit (0x20AC & 0xFF = 0xAC / 172), it renders in CP858 as '½' (one-half)!
      const textEuro = '€';
      expect(textEuro.codeUnits, equals([0x20AC]));
      expect(
        textEuro.codeUnits.first & 0xFF,
        equals(0xAC),
      ); // '½' instead of '€'
      expect(
        textEuro.codeUnits.first & 0xFF,
        isNot(equals(0xD5)),
      ); // 0xD5 is CP858 Euro
    });

    test('Turkish: "Ğ", "ş", "İ" are corrupted by .codeUnits', () {
      // In CP857 (Turkish):
      // "Ğ" (U+011E) -> expected 0xA6 (166). .codeUnits: 0x011E & 0xFF = 0x1E (RS control character!)
      // "ş" (U+015F) -> expected 0x9F (159). .codeUnits: 0x015F & 0xFF = 0x5F (ASCII '_')
      // "İ" (U+0130) -> expected 0x98 (152). .codeUnits: 0x0130 & 0xFF = 0x30 (ASCII '0')
      const turkishText = 'Ğşİ';
      final codeUnits = turkishText.codeUnits;
      final truncatedBytes = codeUnits.map((u) => u & 0xFF).toList();

      expect(
        truncatedBytes,
        equals([0x1E, 0x5F, 0x30]),
      ); // Garbage: [RS, '_', '0']
      expect(
        truncatedBytes,
        isNot(equals([0xA6, 0x9F, 0x98])),
      ); // Expected CP857 bytes
    });

    test('Cyrillic: "Привет" is corrupted by .codeUnits', () {
      // In CP866 (Cyrillic):
      // "П" (U+041F) -> expected 0x8F (143)
      // "р" (U+0440) -> expected 0xE0 (224)
      // "и" (U+0438) -> expected 0xA8 (168)
      // "в" (U+0432) -> expected 0xA2 (162)
      // "е" (U+0435) -> expected 0xA5 (165)
      // "т" (U+0442) -> expected 0xE2 (226)
      const cyrillic = 'Привет';
      final codeUnits = cyrillic.codeUnits;
      final truncatedBytes = codeUnits.map((u) => u & 0xFF).toList();

      // Truncated code units produce ASCII control chars + punctuation:
      // 0x1F (US), 0x40 ('@'), 0x38 ('8'), 0x32 ('2'), 0x35 ('5'), 0x42 ('B') -> "@825B"
      expect(truncatedBytes, equals([0x1F, 0x40, 0x38, 0x32, 0x35, 0x42]));
      expect(
        truncatedBytes,
        isNot(equals([0x8F, 0xE0, 0xA8, 0xA2, 0xA5, 0xE2])),
      );
    });
  });
}
