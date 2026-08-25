import 'dart:convert';
import 'dart:typed_data';

/// Pure Dart standard QR Code matrix generator for preview rendering.
///
/// Supports QR Code Models 1-10 with Byte (8-bit UTF-8) mode and ECC levels L, M, Q, H.
class QrCodeMatrix {
  final int size;
  final List<List<bool>> modules;

  const QrCodeMatrix({
    required this.size,
    required this.modules,
  });

  bool isDark(int row, int col) => modules[row][col];
}

class QrCodeEncoder {
  /// Attempt to encode [content] as a QR Code matrix.
  /// Returns null if payload is empty or exceeds supported version capacity.
  static QrCodeMatrix? encode(String content, {String ecc = 'M'}) {
    if (content.isEmpty) return null;

    final dataBytes = Uint8List.fromList(utf8.encode(content));
    final eccLevel = ecc.toUpperCase();

    // Determine minimum version required for Byte mode
    final version = _findMinimumVersion(dataBytes.length, eccLevel);
    if (version == null) return null;

    return _generateMatrix(dataBytes, version, eccLevel);
  }

  // Capacity table for Byte mode (data bytes capacity) for Versions 1 to 10
  // Index 0: L, 1: M, 2: Q, 3: H
  static const List<List<int>> _byteCapacity = [
    [17, 14, 11, 7], // V1 (21x21)
    [32, 26, 20, 14], // V2 (25x25)
    [53, 42, 32, 24], // V3 (29x29)
    [78, 62, 46, 34], // V4 (33x33)
    [106, 84, 60, 44], // V5 (37x37)
    [134, 106, 74, 58], // V6 (41x41)
    [154, 122, 86, 64], // V7 (45x45)
    [192, 152, 108, 84], // V8 (49x49)
    [230, 180, 130, 98], // V9 (53x53)
    [271, 213, 151, 119], // V10 (57x57)
  ];

  static const List<List<int>> _totalDataCodewords = [
    [19, 16, 13, 9], // V1
    [34, 28, 22, 16], // V2
    [55, 44, 34, 26], // V3
    [80, 64, 48, 36], // V4
    [108, 86, 62, 46], // V5
    [136, 108, 76, 60], // V6
    [156, 124, 88, 66], // V7
    [194, 154, 110, 86], // V8
    [232, 182, 132, 100], // V9
    [274, 216, 154, 122], // V10
  ];

  static const List<List<int>> _eccCodewordsPerBlock = [
    [7, 10, 13, 17], // V1
    [10, 16, 22, 28], // V2
    [15, 26, 18, 22], // V3
    [20, 18, 26, 16], // V4
    [26, 24, 18, 22], // V5
    [18, 16, 24, 28], // V6
    [20, 18, 18, 26], // V7
    [24, 22, 22, 26], // V8
    [30, 22, 20, 24], // V9
    [18, 26, 24, 28], // V10
  ];

  static const List<List<int>> _eccBlocks = [
    [1, 1, 1, 1], // V1
    [1, 1, 1, 1], // V2
    [1, 1, 2, 2], // V3
    [1, 2, 2, 4], // V4
    [1, 2, 4, 4], // V5
    [2, 4, 4, 4], // V6
    [2, 4, 6, 5], // V7
    [2, 4, 6, 6], // V8
    [2, 5, 8, 8], // V9
    [4, 5, 8, 8], // V10
  ];

  static int _eccIndex(String ecc) {
    switch (ecc) {
      case 'L':
        return 0;
      case 'M':
        return 1;
      case 'Q':
        return 2;
      case 'H':
        return 3;
      default:
        return 1;
    }
  }

  static int? _findMinimumVersion(int length, String ecc) {
    final idx = _eccIndex(ecc);
    for (var v = 0; v < _byteCapacity.length; v++) {
      if (length <= _byteCapacity[v][idx]) {
        return v + 1;
      }
    }
    return null;
  }

  // Galois field tables for GF(256)
  static final List<int> _gfExp = List<int>.filled(512, 0);
  static final List<int> _gfLog = List<int>.filled(256, 0);
  static bool _gfInitialized = false;

  static void _initGf() {
    if (_gfInitialized) return;
    var x = 1;
    for (var i = 0; i < 255; i++) {
      _gfExp[i] = x;
      _gfLog[x] = i;
      x <<= 1;
      if ((x & 0x100) != 0) {
        x ^= 0x11D;
      }
    }
    for (var i = 255; i < 512; i++) {
      _gfExp[i] = _gfExp[i - 255];
    }
    _gfInitialized = true;
  }

  static int _gfMul(int x, int y) {
    if (x == 0 || y == 0) return 0;
    return _gfExp[_gfLog[x] + _gfLog[y]];
  }

  static List<int> _rsGeneratorPoly(int degree) {
    _initGf();
    var poly = <int>[1];
    for (var i = 0; i < degree; i++) {
      final next = List<int>.filled(poly.length + 1, 0);
      final factor = _gfExp[i];
      for (var j = 0; j < poly.length; j++) {
        next[j] ^= _gfMul(poly[j], factor);
        next[j + 1] ^= poly[j];
      }
      poly = next;
    }
    return poly;
  }

  static List<int> _calculateEcc(List<int> data, int eccCount) {
    _initGf();
    final generator = _rsGeneratorPoly(eccCount);
    final remainder = List<int>.filled(eccCount, 0);

    for (final b in data) {
      final factor = b ^ remainder[0];
      for (var i = 0; i < eccCount - 1; i++) {
        remainder[i] =
            remainder[i + 1] ^ _gfMul(generator[eccCount - 1 - i], factor);
      }
      remainder[eccCount - 1] = _gfMul(generator[0], factor);
    }

    return remainder;
  }

  static QrCodeMatrix _generateMatrix(Uint8List data, int version, String ecc) {
    final eccIdx = _eccIndex(ecc);
    final totalData = _totalDataCodewords[version - 1][eccIdx];
    final numBlocks = _eccBlocks[version - 1][eccIdx];
    final eccPerBlock = _eccCodewordsPerBlock[version - 1][eccIdx];

    // Build data bitstream
    final bits = <int>[];

    void pushBits(int value, int count) {
      for (var i = count - 1; i >= 0; i--) {
        bits.add((value >> i) & 1);
      }
    }

    // Mode: Byte = 0100
    pushBits(4, 4);

    // Character count indicator (8 bits for V1-9, 16 bits for V10+)
    pushBits(data.length, version < 10 ? 8 : 16);

    // Data bytes
    for (final b in data) {
      pushBits(b, 8);
    }

    // Terminator (up to 4 zeroes)
    final capacityBits = totalData * 8;
    final termLen = (capacityBits - bits.length).clamp(0, 4);
    pushBits(0, termLen);

    // Pad to byte boundary
    while (bits.length % 8 != 0) {
      bits.add(0);
    }

    // Pad with 0xEC and 0x11
    final padBytes = [0xEC, 0x11];
    var padIdx = 0;
    while (bits.length < capacityBits) {
      pushBits(padBytes[padIdx % 2], 8);
      padIdx++;
    }

    // Convert bits to data codewords
    final dataCodewords = <int>[];
    for (var i = 0; i < bits.length; i += 8) {
      var byteVal = 0;
      for (var b = 0; b < 8; b++) {
        byteVal = (byteVal << 1) | bits[i + b];
      }
      dataCodewords.add(byteVal);
    }

    // Divide into blocks and compute ECC
    final blocksData = <List<int>>[];
    final blocksEcc = <List<int>>[];
    final baseBlockSize = totalData ~/ numBlocks;
    final numLargerBlocks = totalData % numBlocks;

    var offset = 0;
    for (var i = 0; i < numBlocks; i++) {
      final size = baseBlockSize + (i >= numBlocks - numLargerBlocks ? 1 : 0);
      final block = dataCodewords.sublist(offset, offset + size);
      offset += size;
      blocksData.add(block);
      blocksEcc.add(_calculateEcc(block, eccPerBlock));
    }

    // Interleave data codewords
    final finalCodewords = <int>[];
    final maxDataBlock = baseBlockSize + (numLargerBlocks > 0 ? 1 : 0);
    for (var i = 0; i < maxDataBlock; i++) {
      for (var b = 0; b < numBlocks; b++) {
        if (i < blocksData[b].length) {
          finalCodewords.add(blocksData[b][i]);
        }
      }
    }

    // Interleave ECC codewords
    for (var i = 0; i < eccPerBlock; i++) {
      for (var b = 0; b < numBlocks; b++) {
        finalCodewords.add(blocksEcc[b][i]);
      }
    }

    // Place into matrix
    final size = 17 + version * 4;
    final matrix = List.generate(size, (_) => List<bool>.filled(size, false));
    final isFunction =
        List.generate(size, (_) => List<bool>.filled(size, false));

    void setModule(int r, int c, bool val, {bool fn = true}) {
      if (r >= 0 && r < size && c >= 0 && c < size) {
        matrix[r][c] = val;
        if (fn) isFunction[r][c] = true;
      }
    }

    void drawFinder(int startR, int startC) {
      for (var r = 0; r < 7; r++) {
        for (var c = 0; c < 7; c++) {
          final isBorder = (r == 0 || r == 6 || c == 0 || c == 6);
          final isCenter = (r >= 2 && r <= 4 && c >= 2 && c <= 4);
          setModule(startR + r, startC + c, isBorder || isCenter);
        }
      }
      // Separator
      for (var i = -1; i <= 7; i++) {
        setModule(startR - 1, startC + i, false);
        setModule(startR + 7, startC + i, false);
        setModule(startR + i, startC - 1, false);
        setModule(startR + i, startC + 7, false);
      }
    }

    // 1. Finder patterns
    drawFinder(0, 0);
    drawFinder(0, size - 7);
    drawFinder(size - 7, 0);

    // 2. Alignment patterns (for Version >= 2)
    if (version >= 2) {
      final alignPositions = _alignmentPositions[version - 1];
      for (final r in alignPositions) {
        for (final c in alignPositions) {
          if (isFunction[r][c]) continue; // Skip if overlapping finder
          for (var dr = -2; dr <= 2; dr++) {
            for (var dc = -2; dc <= 2; dc++) {
              final isBorder = (dr.abs() == 2 || dc.abs() == 2);
              final isCenter = (dr == 0 && dc == 0);
              setModule(r + dr, c + dc, isBorder || isCenter);
            }
          }
        }
      }
    }

    // 3. Timing patterns
    for (var i = 8; i < size - 8; i++) {
      final val = (i % 2 == 0);
      setModule(6, i, val);
      setModule(i, 6, val);
    }

    // 4. Dark module at (4*V + 9, 8)
    setModule(4 * version + 9, 8, true);

    // 5. Reserve format information areas
    for (var i = 0; i < 9; i++) {
      if (!isFunction[8][i]) setModule(8, i, false);
      if (!isFunction[i][8]) setModule(i, 8, false);
    }
    for (var i = 0; i < 8; i++) {
      if (!isFunction[8][size - 1 - i]) setModule(8, size - 1 - i, false);
      if (!isFunction[size - 1 - i][8]) setModule(size - 1 - i, 8, false);
    }

    // 6. Version information for Version >= 7
    if (version >= 7) {
      final vInfo = _versionInfo[version - 7];
      for (var i = 0; i < 18; i++) {
        final bit = ((vInfo >> i) & 1) == 1;
        final r = i ~/ 3;
        final c = i % 3;
        // Top-right
        setModule(r, size - 11 + c, bit);
        // Bottom-left
        setModule(size - 11 + c, r, bit);
      }
    }

    // Convert final codewords to bits
    final allBits = <int>[];
    for (final cw in finalCodewords) {
      for (var b = 7; b >= 0; b--) {
        allBits.add((cw >> b) & 1);
      }
    }

    // 7. Place data bits using zig-zag upward/downward pattern with Mask 0 ((r+c)%2 == 0)
    var bitIdx = 0;
    var upward = true;

    for (var right = size - 1; right > 0; right -= 2) {
      if (right == 6) right--; // Skip vertical timing pattern column

      final rows = upward
          ? List.generate(size, (i) => size - 1 - i)
          : List.generate(size, (i) => i);

      for (final r in rows) {
        for (var cOffset = 0; cOffset < 2; cOffset++) {
          final c = right - cOffset;
          if (!isFunction[r][c]) {
            var bit = bitIdx < allBits.length ? allBits[bitIdx] : 0;
            bitIdx++;
            // Apply mask 0: (r + c) % 2 == 0
            if ((r + c) % 2 == 0) {
              bit ^= 1;
            }
            matrix[r][c] = (bit == 1);
          }
        }
      }
      upward = !upward;
    }

    // 8. Write Format Information (for ECC + Mask 0)
    final formatBits = _formatInfo[eccIdx];
    for (var i = 0; i < 15; i++) {
      final bit = ((formatBits >> (14 - i)) & 1) == 1;
      // Top-left area
      if (i < 6) {
        matrix[8][i] = bit;
      } else if (i < 8) {
        matrix[8][i + 1] = bit;
      } else if (i == 8) {
        matrix[7][8] = bit;
      } else {
        matrix[14 - i][8] = bit;
      }

      // Bottom / right area (7 bits at bottom-left, 8 bits at top-right)
      if (i < 7) {
        matrix[size - 1 - i][8] = bit;
      } else {
        matrix[8][size - 15 + i] = bit;
      }
    }

    return QrCodeMatrix(size: size, modules: matrix);
  }

  // Precomputed Format Information with BCH(15,5) and mask XOR 0x5412 for Mask 0
  static const List<int> _formatInfo = [
    0x77C4, // L, mask 0
    0x5412, // M, mask 0
    0x355F, // Q, mask 0
    0x1689, // H, mask 0
  ];

  // Version information for Versions 7 to 10 with BCH(18,6)
  static const List<int> _versionInfo = [
    0x07C94, // V7
    0x085BC, // V8
    0x09A99, // V9
    0x0A4D3, // V10
  ];

  static const List<List<int>> _alignmentPositions = [
    [], // V1
    [6, 18], // V2
    [6, 22], // V3
    [6, 26], // V4
    [6, 30], // V5
    [6, 34], // V6
    [6, 22, 38], // V7
    [6, 24, 42], // V8
    [6, 26, 46], // V9
    [6, 28, 50], // V10
  ];
}
