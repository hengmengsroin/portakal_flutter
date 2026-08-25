/// Visual pattern descriptor for 1D barcodes.
class BarcodeVisualPattern {
  /// Width of each module/bar relative to unit width.
  /// Alternates: bar, space, bar, space, ...
  final List<int> moduleWidths;
  final int totalModules;

  const BarcodeVisualPattern({
    required this.moduleWidths,
    required this.totalModules,
  });
}

class BarcodeEncoder {
  /// Attempt to encode [content] as a 1D barcode pattern.
  /// Returns null if symbology is unsupported or payload contains invalid characters.
  static BarcodeVisualPattern? encode(String type, String content) {
    final normalizedType = type.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

    if (normalizedType == '128' || normalizedType == 'CODE128') {
      return _encodeCode128(content);
    } else if (normalizedType == '39' || normalizedType == 'CODE39') {
      return _encodeCode39(content);
    } else if (normalizedType == 'EAN13') {
      return _encodeEan13(content);
    } else if (normalizedType == 'EAN8') {
      return _encodeEan8(content);
    }

    return null;
  }

  // ==========================================
  // CODE 128 (Code Set B)
  // ==========================================
  static const List<List<int>> _code128Patterns = [
    [2, 1, 2, 2, 2, 2], [2, 2, 2, 1, 2, 2], [2, 2, 2, 2, 2, 1], [1, 2, 1, 2, 2, 3],
    [1, 2, 1, 3, 2, 2], [1, 3, 1, 2, 2, 2], [1, 2, 2, 2, 1, 3], [1, 2, 2, 3, 1, 2],
    [1, 3, 2, 2, 1, 2], [2, 2, 1, 2, 1, 3], [2, 2, 1, 3, 1, 2], [2, 3, 1, 2, 1, 2],
    [1, 1, 2, 2, 3, 2], [1, 2, 2, 1, 3, 2], [1, 2, 2, 2, 3, 1], [1, 1, 3, 2, 2, 2],
    [1, 2, 3, 1, 2, 2], [1, 2, 3, 2, 2, 1], [2, 2, 3, 2, 1, 1], [2, 2, 1, 1, 3, 2],
    [2, 2, 1, 2, 3, 1], [2, 1, 3, 2, 1, 2], [2, 2, 3, 1, 1, 2], [3, 1, 2, 1, 3, 1],
    [3, 1, 1, 2, 2, 2], [3, 2, 1, 1, 2, 2], [3, 2, 1, 2, 2, 1], [3, 1, 2, 2, 1, 2],
    [3, 2, 2, 1, 1, 2], [3, 2, 2, 2, 1, 1], [2, 1, 2, 1, 2, 3], [2, 1, 2, 3, 2, 1],
    [2, 3, 2, 1, 2, 1], [1, 1, 1, 3, 2, 3], [1, 3, 1, 1, 2, 3], [1, 3, 1, 3, 2, 1],
    [1, 1, 2, 3, 1, 3], [1, 3, 2, 1, 1, 3], [1, 3, 2, 3, 1, 1], [2, 1, 1, 3, 1, 3],
    [2, 3, 1, 1, 1, 3], [2, 3, 1, 3, 1, 1], [1, 1, 2, 1, 3, 3], [1, 1, 2, 3, 3, 1],
    [1, 3, 2, 1, 3, 1], [1, 1, 3, 1, 2, 3], [1, 1, 3, 3, 2, 1], [1, 3, 3, 1, 2, 1],
    [3, 1, 3, 1, 2, 1], [2, 1, 1, 3, 3, 1], [2, 3, 1, 1, 3, 1], [2, 1, 3, 1, 1, 3],
    [2, 1, 3, 3, 1, 1], [2, 1, 3, 1, 3, 1], [3, 1, 1, 1, 2, 3], [3, 1, 1, 3, 2, 1],
    [3, 3, 1, 1, 2, 1], [3, 1, 2, 1, 1, 3], [3, 1, 2, 3, 1, 1], [3, 3, 2, 1, 1, 1],
    [3, 1, 4, 1, 1, 1], [2, 2, 1, 4, 1, 1], [4, 3, 1, 1, 1, 1], [1, 1, 1, 2, 2, 4],
    [1, 1, 1, 4, 2, 2], [1, 2, 1, 1, 2, 4], [1, 2, 1, 4, 2, 1], [1, 4, 1, 1, 2, 2],
    [1, 4, 1, 2, 2, 1], [1, 1, 2, 2, 1, 4], [1, 1, 2, 4, 1, 2], [1, 2, 2, 1, 1, 4],
    [1, 2, 2, 4, 1, 1], [1, 4, 2, 1, 1, 2], [1, 4, 2, 2, 1, 1], [2, 4, 1, 2, 1, 1],
    [2, 2, 1, 1, 1, 4], [4, 1, 3, 1, 1, 1], [2, 4, 1, 1, 1, 2], [1, 3, 4, 1, 1, 1],
    [1, 1, 1, 2, 4, 2], [1, 2, 1, 1, 4, 2], [1, 2, 1, 2, 4, 1], [1, 1, 4, 2, 1, 2],
    [1, 2, 4, 1, 1, 2], [1, 2, 4, 2, 1, 1], [4, 1, 1, 2, 1, 2], [4, 2, 1, 1, 1, 2],
    [4, 2, 1, 2, 1, 1], [2, 1, 2, 1, 4, 1], [2, 1, 4, 1, 2, 1], [4, 1, 2, 1, 2, 1],
    [1, 1, 1, 1, 4, 3], [1, 1, 1, 3, 4, 1], [1, 3, 1, 1, 4, 1], [1, 1, 4, 1, 1, 3],
    [1, 1, 4, 3, 1, 1], [4, 1, 1, 1, 1, 3], [4, 1, 1, 3, 1, 1], [1, 1, 3, 1, 4, 1],
    [1, 1, 4, 1, 3, 1], [3, 1, 1, 1, 4, 1], [4, 1, 1, 1, 3, 1], [2, 1, 1, 4, 1, 2],
    [2, 1, 1, 2, 1, 4], [2, 1, 1, 2, 3, 2], [2, 3, 3, 1, 1, 1, 2] // 106 = STOP
  ];

  static BarcodeVisualPattern? _encodeCode128(String content) {
    if (content.isEmpty) return null;

    final symbols = <int>[];
    // Start with Code Set B (index 104)
    symbols.add(104);

    for (var i = 0; i < content.length; i++) {
      final code = content.codeUnitAt(i);
      if (code < 32 || code > 127) return null; // Outside ASCII printable
      symbols.add(code - 32);
    }

    // Checksum: (start_val + sum(val * pos)) % 103
    var checksum = symbols.first;
    for (var i = 1; i < symbols.length; i++) {
      checksum += symbols[i] * i;
    }
    symbols.add(checksum % 103);
    symbols.add(106); // Stop symbol

    final widths = <int>[];
    var total = 0;
    for (final sym in symbols) {
      final pattern = _code128Patterns[sym];
      for (final w in pattern) {
        widths.add(w);
        total += w;
      }
    }

    return BarcodeVisualPattern(moduleWidths: widths, totalModules: total);
  }

  // ==========================================
  // CODE 39
  // ==========================================
  static const Map<String, String> _code39Patterns = {
    '0': '101001101', '1': '110100101', '2': '101100101', '3': '110110010',
    '4': '101001101', '5': '110100110', '6': '101100110', '7': '101001011',
    '8': '110100101', '9': '101100101', 'A': '110101001', 'B': '101101001',
    'C': '110110100', 'D': '101011001', 'E': '110101100', 'F': '101101100',
    'G': '101010011', 'H': '110101010', 'I': '101101010', 'J': '101011010',
    'K': '110101010', 'L': '101101010', 'M': '110110101', 'N': '101011010',
    'O': '110101101', 'P': '101101101', 'Q': '101010111', 'R': '110101011',
    'S': '101101011', 'T': '101011011', 'U': '110010101', 'V': '100110101',
    'W': '110011010', 'X': '100101101', 'Y': '110010110', 'Z': '100110110',
    '-': '100101011', '.': '110010101', ' ': '100110101', '\$': '100100100',
    '/': '100100100', '+': '100100100', '%': '101001001', '*': '100101101'
  };

  static BarcodeVisualPattern? _encodeCode39(String content) {
    final upper = content.toUpperCase();
    final full = '*$upper*';
    final widths = <int>[];
    var total = 0;

    for (var i = 0; i < full.length; i++) {
      final ch = full[i];
      final pattern = _code39Patterns[ch];
      if (pattern == null) return null;

      // 9 elements: alternates bar (1=narrow, 2=wide), space (0=narrow, 2=wide)
      for (var j = 0; j < 9; j++) {
        final isBar = (j % 2 == 0);
        final bit = pattern[j];
        final w = isBar ? (bit == '1' ? 2 : 1) : (bit == '1' ? 2 : 1);
        widths.add(w);
        total += w;
      }
      // Inter-character space (narrow space = 1)
      if (i < full.length - 1) {
        widths.add(1);
        total += 1;
      }
    }

    return BarcodeVisualPattern(moduleWidths: widths, totalModules: total);
  }

  // ==========================================
  // EAN-13 & EAN-8
  // ==========================================
  static const List<String> _eanL = [
    '0001101', '0011001', '0010011', '0111101', '0100011',
    '0110001', '0101111', '0111011', '0110111', '0001011'
  ];
  static const List<String> _eanG = [
    '0100111', '0110011', '0011011', '0100001', '0011101',
    '0111001', '0000101', '0010001', '0001001', '0010111'
  ];
  static const List<String> _eanR = [
    '1110010', '1100110', '1101100', '1000010', '1011100',
    '1001110', '1010000', '1000100', '1001000', '1110100'
  ];
  static const List<String> _eanStructure = [
    'LLLLLL', 'LLGLGG', 'LLGGLG', 'LLGGGL', 'LGLLGG',
    'LGGLLG', 'LGGGLL', 'LGLGLG', 'LGLGGL', 'LGGLGL'
  ];

  static BarcodeVisualPattern? _encodeEan13(String content) {
    if (!RegExp(r'^\d{12,13}$').hasMatch(content)) return null;

    final digits = content.split('').map(int.parse).toList();
    if (digits.length == 12) {
      // Calculate checksum digit
      var sum = 0;
      for (var i = 0; i < 12; i++) {
        sum += digits[i] * (i % 2 == 0 ? 1 : 3);
      }
      final check = (10 - (sum % 10)) % 10;
      digits.add(check);
    }

    final first = digits[0];
    final struct = _eanStructure[first];
    final bitBuffer = StringBuffer();

    // Start guard: 101
    bitBuffer.write('101');

    // Left 6 digits
    for (var i = 1; i <= 6; i++) {
      final d = digits[i];
      final mode = struct[i - 1];
      bitBuffer.write(mode == 'L' ? _eanL[d] : _eanG[d]);
    }

    // Center guard: 01010
    bitBuffer.write('01010');

    // Right 6 digits
    for (var i = 7; i <= 12; i++) {
      final d = digits[i];
      bitBuffer.write(_eanR[d]);
    }

    // End guard: 101
    bitBuffer.write('101');

    return _bitStringToPattern(bitBuffer.toString());
  }

  static BarcodeVisualPattern? _encodeEan8(String content) {
    if (!RegExp(r'^\d{7,8}$').hasMatch(content)) return null;

    final digits = content.split('').map(int.parse).toList();
    if (digits.length == 7) {
      var sum = 0;
      for (var i = 0; i < 7; i++) {
        sum += digits[i] * (i % 2 == 0 ? 3 : 1);
      }
      final check = (10 - (sum % 10)) % 10;
      digits.add(check);
    }

    final bitBuffer = StringBuffer();
    bitBuffer.write('101'); // Start guard

    for (var i = 0; i < 4; i++) {
      bitBuffer.write(_eanL[digits[i]]);
    }

    bitBuffer.write('01010'); // Center guard

    for (var i = 4; i < 8; i++) {
      bitBuffer.write(_eanR[digits[i]]);
    }

    bitBuffer.write('101'); // End guard

    return _bitStringToPattern(bitBuffer.toString());
  }

  static BarcodeVisualPattern _bitStringToPattern(String bitString) {
    final widths = <int>[];
    var currentBit = '1';
    var currentCount = 0;

    for (var i = 0; i < bitString.length; i++) {
      final b = bitString[i];
      if (b == currentBit) {
        currentCount++;
      } else {
        widths.add(currentCount);
        currentBit = b;
        currentCount = 1;
      }
    }
    if (currentCount > 0) {
      widths.add(currentCount);
    }

    return BarcodeVisualPattern(
      moduleWidths: widths,
      totalModules: bitString.length,
    );
  }
}
