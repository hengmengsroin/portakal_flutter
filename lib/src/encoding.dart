import 'dart:typed_data';

/// A segment of encoded text with its code page.
class EncodedSegment {
  final int codePage; // -1 = ASCII (no switch needed)
  final Uint8List data;

  const EncodedSegment({required this.codePage, required this.data});
}

/// Code page definition.
class CodePage {
  final int escPosId;
  final Map<int, int> charMap; // Unicode codepoint → byte value

  const CodePage({required this.escPosId, required this.charMap});
}

// CP437 — IBM PC / US
final Map<int, int> _cp437Map = {
  0x00C7: 0x80, 0x00FC: 0x81, 0x00E9: 0x82, 0x00E2: 0x83,
  0x00E4: 0x84, 0x00E0: 0x85, 0x00E5: 0x86, 0x00E7: 0x87,
  0x00EA: 0x88, 0x00EB: 0x89, 0x00E8: 0x8A, 0x00EF: 0x8B,
  0x00EE: 0x8C, 0x00EC: 0x8D, 0x00C4: 0x8E, 0x00C5: 0x8F,
  0x00C9: 0x90, 0x00E6: 0x91, 0x00C6: 0x92, 0x00F4: 0x93,
  0x00F6: 0x94, 0x00F2: 0x95, 0x00FB: 0x96, 0x00F9: 0x97,
  0x00FF: 0x98, 0x00D6: 0x99, 0x00DC: 0x9A, 0x00A2: 0x9B,
  0x00A3: 0x9C, 0x00A5: 0x9D, 0x00DF: 0xE1, 0x00B5: 0xE6,
  0x00F1: 0xA4, 0x00D1: 0xA5,
};

// CP858 — Western European with Euro
final Map<int, int> _cp858Map = {
  ..._cp437Map,
  0x20AC: 0xD5, // € Euro sign
};

// CP1252 — Windows Western
final Map<int, int> _cp1252Map = {
  0x20AC: 0x80, 0x201A: 0x82, 0x0192: 0x83, 0x201E: 0x84,
  0x2026: 0x85, 0x2020: 0x86, 0x2021: 0x87, 0x02C6: 0x88,
  0x2030: 0x89, 0x0160: 0x8A, 0x2039: 0x8B, 0x0152: 0x8C,
  0x017D: 0x8E, 0x2018: 0x91, 0x2019: 0x92, 0x201C: 0x93,
  0x201D: 0x94, 0x2022: 0x95, 0x2013: 0x96, 0x2014: 0x97,
  0x02DC: 0x98, 0x2122: 0x99, 0x0161: 0x9A, 0x203A: 0x9B,
  0x0153: 0x9C, 0x017E: 0x9E, 0x0178: 0x9F,
};

// CP866 — Cyrillic (Russian)
final Map<int, int> _cp866Map = () {
  final m = <int, int>{};
  // А-Я (U+0410-U+042F) → 0x80-0x9F
  for (int i = 0; i < 32; i++) {
    m[0x0410 + i] = 0x80 + i;
  }
  // а-п (U+0430-U+043F) → 0xA0-0xAF
  for (int i = 0; i < 16; i++) {
    m[0x0430 + i] = 0xA0 + i;
  }
  // р-я (U+0440-U+044F) → 0xE0-0xEF
  for (int i = 0; i < 16; i++) {
    m[0x0440 + i] = 0xE0 + i;
  }
  return m;
}();

// CP857 — Turkish
final Map<int, int> _cp857Map = {
  ..._cp437Map,
  0x011E: 0xA6, // Ğ
  0x011F: 0xA7, // ğ
  0x0130: 0x98, // İ
  0x0131: 0x8D, // ı
  0x015E: 0x9E, // Ş
  0x015F: 0x9F, // ş
};

/// All supported code pages in priority order.
final List<CodePage> _codePages = [
  CodePage(escPosId: 0, charMap: _cp437Map),     // CP437
  CodePage(escPosId: 19, charMap: _cp858Map),     // CP858
  CodePage(escPosId: 16, charMap: _cp1252Map),    // CP1252
  CodePage(escPosId: 17, charMap: _cp866Map),     // CP866
  CodePage(escPosId: 13, charMap: _cp857Map),     // CP857
];

/// Check if a string contains only ASCII printable characters + newlines.
bool isASCII(String text) {
  for (final rune in text.runes) {
    if (rune == 0x0A || rune == 0x0D) continue; // LF, CR allowed
    if (rune < 0x20 || rune > 0x7E) return false;
  }
  return true;
}

/// Find the best code page for a Unicode codepoint.
/// Returns (escPosId, byteValue) or null if not encodable.
(int, int)? _findCodePage(int codepoint) {
  for (final cp in _codePages) {
    final byte = cp.charMap[codepoint];
    if (byte != null) return (cp.escPosId, byte);
  }
  return null;
}

/// Encode text into segments with code page information.
///
/// ASCII characters go into segments with codePage=-1.
/// Non-ASCII characters are mapped to the best code page.
/// Unencodable characters become '?' (0x3F).
List<EncodedSegment> encodeText(String text) {
  if (text.isEmpty) return [];

  final segments = <EncodedSegment>[];
  int currentCodePage = -1;
  final currentBytes = <int>[];

  void flushSegment() {
    if (currentBytes.isNotEmpty) {
      segments.add(EncodedSegment(
        codePage: currentCodePage,
        data: Uint8List.fromList(currentBytes),
      ));
      currentBytes.clear();
    }
  }

  for (final rune in text.runes) {
    if (rune >= 0x20 && rune <= 0x7E || rune == 0x0A || rune == 0x0D) {
      // ASCII
      if (currentCodePage != -1) {
        flushSegment();
        currentCodePage = -1;
      }
      currentBytes.add(rune);
    } else {
      final result = _findCodePage(rune);
      if (result != null) {
        final (cpId, byteVal) = result;
        if (currentCodePage != cpId) {
          flushSegment();
          currentCodePage = cpId;
        }
        currentBytes.add(byteVal);
      } else {
        // Unencodable — use '?'
        if (currentCodePage != -1) {
          flushSegment();
          currentCodePage = -1;
        }
        currentBytes.add(0x3F); // '?'
      }
    }
  }

  flushSegment();
  return segments;
}

/// Encode text for printer with ESC t code page switch commands.
///
/// Returns complete byte sequence with ESC t N prefixes
/// for code page switches.
Uint8List encodeTextForPrinter(String text) {
  final segments = encodeText(text);
  final bytes = <int>[];

  for (final seg in segments) {
    if (seg.codePage >= 0) {
      // ESC t N — select code page
      bytes.addAll([0x1B, 0x74, seg.codePage]);
    }
    bytes.addAll(seg.data);
  }

  return Uint8List.fromList(bytes);
}
