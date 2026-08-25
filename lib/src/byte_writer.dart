import 'dart:convert';
import 'dart:typed_data';

/// High-performance, byte-safe builder for printer command serialization.
///
/// Ensures arbitrary binary payloads (such as raster bitmaps and raw printer
/// control sequences) are preserved without intermediate UTF-16/UTF-8 String
/// transformations.
class PrinterByteWriter {
  final BytesBuilder _builder;

  /// Creates a new [PrinterByteWriter].
  ///
  /// If [copy] is false, the internal [BytesBuilder] may avoid copying buffers
  /// when possible for higher performance.
  PrinterByteWriter({bool copy = false}) : _builder = BytesBuilder(copy: copy);

  /// Current number of bytes written.
  int get length => _builder.length;

  /// Whether the writer contains zero bytes.
  bool get isEmpty => _builder.isEmpty;

  /// Whether the writer contains one or more bytes.
  bool get isNotEmpty => _builder.isNotEmpty;

  /// Appends a single byte (0..255).
  ///
  /// Throws [RangeError] if [value] is less than 0 or greater than 255.
  void writeByte(int value) {
    if (value < 0 || value > 255) {
      throw RangeError.range(
        value,
        0,
        255,
        'value',
        'Byte value must be in range 0..255',
      );
    }
    _builder.addByte(value);
  }

  /// Appends a sequence of bytes.
  ///
  /// Throws [RangeError] if any element in [bytes] is outside 0..255.
  void writeBytes(Iterable<int> bytes) {
    if (bytes is Uint8List) {
      _builder.add(bytes);
    } else {
      for (final b in bytes) {
        if (b < 0 || b > 255) {
          throw RangeError.range(
            b,
            0,
            255,
            'bytes',
            'Byte value in sequence must be in range 0..255',
          );
        }
      }
      _builder.add(bytes is List<int> ? bytes : bytes.toList());
    }
  }

  /// Appends an ASCII-only string.
  ///
  /// Throws [ArgumentError] if [text] contains any character with code unit > 127.
  void writeAscii(String text) {
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      if (code > 0x7F) {
        throw ArgumentError.value(
          text,
          'text',
          'writeAscii encountered non-ASCII character (U+${code.toRadixString(16).padLeft(4, '0').toUpperCase()}) at index $i. Use writeEncoded or writeString with an appropriate encoding.',
        );
      }
      _builder.addByte(code);
    }
  }

  /// Appends [text] encoded using the given [encoder] function.
  void writeEncoded(String text, List<int> Function(String) encoder) {
    final encoded = encoder(text);
    writeBytes(encoded);
  }

  /// Appends [text] encoded using the standard [Encoding] (defaults to [ascii]).
  void writeString(String text, {Encoding encoding = ascii}) {
    final encoded = encoding.encode(text);
    _builder.add(encoded);
  }

  /// Returns the accumulated bytes as a [Uint8List].
  Uint8List toBytes() {
    return _builder.toBytes();
  }

  /// Takes the accumulated bytes and resets the writer.
  Uint8List takeBytes() {
    return _builder.takeBytes();
  }

  /// Clears the accumulated bytes.
  void clear() {
    _builder.clear();
  }
}
