import 'dart:typed_data';

/// Formats raw bytes into a deterministic 16-bytes-per-row hex dump.
///
/// Format:
/// `00000000  1B 40 1B 61 01 1B 45 01  1B 2D 01 54 45 53 54 0A`
String formatHexDump(Uint8List bytes) {
  if (bytes.isEmpty) return '';

  final buf = StringBuffer();
  for (int offset = 0; offset < bytes.length; offset += 16) {
    // 8-character offset
    buf.write(offset.toRadixString(16).padLeft(8, '0').toUpperCase());
    buf.write('  ');

    final end = (offset + 16 < bytes.length) ? offset + 16 : bytes.length;
    for (int i = offset; i < offset + 16; i++) {
      if (i < end) {
        buf.write(bytes[i].toRadixString(16).padLeft(2, '0').toUpperCase());
      } else {
        buf.write('  ');
      }

      if (i == offset + 7) {
        buf.write('  '); // Middle space separator between 8-byte halves
      } else if (i < offset + 15) {
        buf.write(' ');
      }
    }
    buf.writeln();
  }

  return buf.toString();
}
