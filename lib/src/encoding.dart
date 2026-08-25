import 'dart:typed_data';

/// Standard 8-bit printer code page character sets.
enum PrinterCodePage {
  /// IBM PC / US (Default on many Epson & thermal POS printers).
  cp437,

  /// Western European (Latin-1 multilingual with Euro sign € at 0xD5).
  cp858,

  /// Western European (Latin-1 multilingual without Euro sign).
  cp850,

  /// Windows-1252 (Western European).
  cp1252,

  /// CP866 / Cyrillic #2 (Russian and Slavic languages).
  cp866,

  /// CP857 (Turkish).
  cp857,
}

/// Exception thrown when a character cannot be represented in the chosen code page.
class UnsupportedCharacterException implements Exception {
  final String character;
  final int codePoint;
  final PrinterCodePage codePage;
  final String message;

  UnsupportedCharacterException({
    required this.character,
    required this.codePoint,
    required this.codePage,
    String? message,
  }) : message =
           message ??
           'Character "$character" (U+${codePoint.toRadixString(16).padLeft(4, '0').toUpperCase()}) '
               'cannot be encoded in code page ${codePage.name}.';

  @override
  String toString() => 'UnsupportedCharacterException: $message';
}

/// Explicit ESC/POS character encoding and table selection configuration.
///
/// Decouples the character mapping ([codePage]) from the printer hardware
/// table selector ([tableId]), since ESC/POS table numbers vary across
/// printer manufacturers and firmware dialects.
class EscPosEncoding {
  /// The 8-bit character mapping to use for user text.
  final PrinterCodePage codePage;

  /// The ESC/POS table selector number (for `ESC t <tableId>`).
  ///
  /// Set to `null` if no table selection command should be emitted.
  final int? tableId;

  /// Whether to emit `ESC t <tableId>` during initialization.
  final bool sendTableSelect;

  /// Whether to replace unencodable characters with `?` (0x3F) instead of
  /// throwing [UnsupportedCharacterException].
  final bool replaceUnsupported;

  const EscPosEncoding({
    required this.codePage,
    this.tableId,
    this.sendTableSelect = true,
    this.replaceUnsupported = false,
  });

  /// Standard CP437 (USA / Standard Europe, Table 0 on Epson).
  const EscPosEncoding.cp437({
    int tableId = 0,
    bool sendTableSelect = true,
    bool replaceUnsupported = false,
  }) : this(
         codePage: PrinterCodePage.cp437,
         tableId: tableId,
         sendTableSelect: sendTableSelect,
         replaceUnsupported: replaceUnsupported,
       );

  /// Standard CP858 (Western European with Euro €, Table 19 on Epson).
  const EscPosEncoding.cp858({
    int tableId = 19,
    bool sendTableSelect = true,
    bool replaceUnsupported = false,
  }) : this(
         codePage: PrinterCodePage.cp858,
         tableId: tableId,
         sendTableSelect: sendTableSelect,
         replaceUnsupported: replaceUnsupported,
       );

  /// Standard CP850 (Multilingual Latin-1, Table 2 on Epson).
  const EscPosEncoding.cp850({
    int tableId = 2,
    bool sendTableSelect = true,
    bool replaceUnsupported = false,
  }) : this(
         codePage: PrinterCodePage.cp850,
         tableId: tableId,
         sendTableSelect: sendTableSelect,
         replaceUnsupported: replaceUnsupported,
       );

  /// Standard Windows-1252 (Western European, Table 16 on Epson).
  const EscPosEncoding.cp1252({
    int tableId = 16,
    bool sendTableSelect = true,
    bool replaceUnsupported = false,
  }) : this(
         codePage: PrinterCodePage.cp1252,
         tableId: tableId,
         sendTableSelect: sendTableSelect,
         replaceUnsupported: replaceUnsupported,
       );

  /// Standard CP866 (Cyrillic #2, Table 17 on Epson).
  const EscPosEncoding.cp866({
    int tableId = 17,
    bool sendTableSelect = true,
    bool replaceUnsupported = false,
  }) : this(
         codePage: PrinterCodePage.cp866,
         tableId: tableId,
         sendTableSelect: sendTableSelect,
         replaceUnsupported: replaceUnsupported,
       );

  /// Standard CP857 (Turkish, Table 13 on Epson).
  const EscPosEncoding.cp857({
    int tableId = 13,
    bool sendTableSelect = true,
    bool replaceUnsupported = false,
  }) : this(
         codePage: PrinterCodePage.cp857,
         tableId: tableId,
         sendTableSelect: sendTableSelect,
         replaceUnsupported: replaceUnsupported,
       );

  /// Custom table assignment (e.g. for non-Epson printers where CP1252 is table 32).
  const EscPosEncoding.custom({
    required PrinterCodePage codePage,
    required int tableId,
    bool sendTableSelect = true,
    bool replaceUnsupported = false,
  }) : this(
         codePage: codePage,
         tableId: tableId,
         sendTableSelect: sendTableSelect,
         replaceUnsupported: replaceUnsupported,
       );

  /// Raw encoding without emitting any `ESC t` table selection command.
  const EscPosEncoding.raw({
    required PrinterCodePage codePage,
    bool replaceUnsupported = false,
  }) : this(
         codePage: codePage,
         tableId: null,
         sendTableSelect: false,
         replaceUnsupported: replaceUnsupported,
       );
}

/// Text encoding mode for Zebra ZPL II serialization.
enum ZplTextEncoding {
  /// Full Unicode UTF-8 encoding with ^CI28 header command (SDK default).
  utf8,

  /// Legacy ASCII / Latin-1 baseline without ^CI28 command.
  legacy,
}

/// Explicit ZPL II encoding configuration.
class ZplEncoding {
  /// The encoding mode to use for ZPL text fields.
  final ZplTextEncoding type;

  /// Whether to emit `^CI28` in the label header when [type] is [ZplTextEncoding.utf8].
  final bool emitCiCommand;

  /// Standard UTF-8 mode with ^CI28 header command (historical and SDK default).
  const ZplEncoding.utf8({this.emitCiCommand = true})
    : type = ZplTextEncoding.utf8;

  /// Legacy mode without ^CI28 command (ASCII / Latin-1 baseline).
  const ZplEncoding.legacy()
    : type = ZplTextEncoding.legacy,
      emitCiCommand = false;

  /// The canonical default ZPL encoding configuration (UTF-8 with ^CI28).
  static const ZplEncoding defaultEncoding = ZplEncoding.utf8();
}

/// Character set and encoding configuration for EPL2 serialization.
class EplEncoding {
  /// The character mapping to use for user text.
  final PrinterCodePage codePage;

  /// The EPL2 character set parameter for `I8,<countryCode>,001` (e.g. 0 for CP437, 1 for CP850, 13 for CP1252, 9 for CP866, 6 for CP857).
  /// Set to null to omit the `I` command.
  final int? countryCode;

  /// Whether to emit `I8,<countryCode>,001\n` in the label preamble.
  final bool sendSetCharSetCommand;

  /// Whether to replace unencodable characters with `?` (0x3F) instead of throwing.
  final bool replaceUnsupported;

  const EplEncoding({
    required this.codePage,
    this.countryCode,
    this.sendSetCharSetCommand = false,
    this.replaceUnsupported = false,
  });

  /// Default legacy EPL mode: CP437 mapping without emitting `I` command (historical baseline).
  const EplEncoding.legacy({bool replaceUnsupported = false})
    : this(
        codePage: PrinterCodePage.cp437,
        countryCode: null,
        sendSetCharSetCommand: false,
        replaceUnsupported: replaceUnsupported,
      );

  /// Standard CP437 (DOS US, country code 0).
  const EplEncoding.cp437({
    bool sendSetCharSetCommand = false,
    bool replaceUnsupported = false,
  }) : this(
         codePage: PrinterCodePage.cp437,
         countryCode: 0,
         sendSetCharSetCommand: sendSetCharSetCommand,
         replaceUnsupported: replaceUnsupported,
       );

  /// Standard CP850 (Multilingual Latin-1, country code 1).
  const EplEncoding.cp850({
    bool sendSetCharSetCommand = true,
    bool replaceUnsupported = false,
  }) : this(
         codePage: PrinterCodePage.cp850,
         countryCode: 1,
         sendSetCharSetCommand: sendSetCharSetCommand,
         replaceUnsupported: replaceUnsupported,
       );

  /// Standard Windows CP1252 (Latin-1, country code 13).
  const EplEncoding.cp1252({
    bool sendSetCharSetCommand = true,
    bool replaceUnsupported = false,
  }) : this(
         codePage: PrinterCodePage.cp1252,
         countryCode: 13,
         sendSetCharSetCommand: sendSetCharSetCommand,
         replaceUnsupported: replaceUnsupported,
       );

  /// Standard CP866 (Cyrillic, country code 9).
  const EplEncoding.cp866({
    bool sendSetCharSetCommand = true,
    bool replaceUnsupported = false,
  }) : this(
         codePage: PrinterCodePage.cp866,
         countryCode: 9,
         sendSetCharSetCommand: sendSetCharSetCommand,
         replaceUnsupported: replaceUnsupported,
       );

  /// Standard CP857 (Turkish, country code 6).
  const EplEncoding.cp857({
    bool sendSetCharSetCommand = true,
    bool replaceUnsupported = false,
  }) : this(
         codePage: PrinterCodePage.cp857,
         countryCode: 6,
         sendSetCharSetCommand: sendSetCharSetCommand,
         replaceUnsupported: replaceUnsupported,
       );

  /// Custom EPL encoding configuration.
  const EplEncoding.custom({
    required PrinterCodePage codePage,
    int? countryCode,
    bool sendSetCharSetCommand = true,
    bool replaceUnsupported = false,
  }) : this(
         codePage: codePage,
         countryCode: countryCode,
         sendSetCharSetCommand: sendSetCharSetCommand,
         replaceUnsupported: replaceUnsupported,
       );

  /// The canonical default EPL encoding (legacy CP437 without `I` command).
  static const EplEncoding defaultEncoding = EplEncoding.legacy();
}

/// Explicit CPCL encoding and COUNTRY selection configuration.
class CpclEncoding {
  /// The character mapping to use for user text.
  final PrinterCodePage codePage;

  /// The CPCL `COUNTRY <name>` argument (e.g. 'USA', 'CP850', 'CP1252', 'CP866', 'CP857').
  /// Set to null if no COUNTRY command should be emitted.
  final String? country;

  /// Whether to emit `COUNTRY <country>\r\n` in the session preamble.
  final bool sendCountryCommand;

  /// Whether to replace unencodable characters with `?` (0x3F) instead of throwing.
  final bool replaceUnsupported;

  const CpclEncoding({
    required this.codePage,
    this.country,
    this.sendCountryCommand = false,
    this.replaceUnsupported = false,
  });

  /// Default legacy CPCL mode: CP437 mapping without emitting `COUNTRY` command (historical baseline).
  const CpclEncoding.legacy({bool replaceUnsupported = false})
    : this(
        codePage: PrinterCodePage.cp437,
        country: null,
        sendCountryCommand: false,
        replaceUnsupported: replaceUnsupported,
      );

  /// Standard USA / CP437 mode.
  const CpclEncoding.usa({
    bool sendCountryCommand = false,
    bool replaceUnsupported = false,
  }) : this(
         codePage: PrinterCodePage.cp437,
         country: 'USA',
         sendCountryCommand: sendCountryCommand,
         replaceUnsupported: replaceUnsupported,
       );

  /// Standard CP850 mode.
  const CpclEncoding.cp850({
    bool sendCountryCommand = true,
    bool replaceUnsupported = false,
  }) : this(
         codePage: PrinterCodePage.cp850,
         country: 'CP850',
         sendCountryCommand: sendCountryCommand,
         replaceUnsupported: replaceUnsupported,
       );

  /// Standard CP1252 (Windows Western) mode.
  const CpclEncoding.cp1252({
    bool sendCountryCommand = true,
    bool replaceUnsupported = false,
  }) : this(
         codePage: PrinterCodePage.cp1252,
         country: 'CP1252',
         sendCountryCommand: sendCountryCommand,
         replaceUnsupported: replaceUnsupported,
       );

  /// Standard CP866 (Cyrillic) mode.
  const CpclEncoding.cp866({
    bool sendCountryCommand = true,
    bool replaceUnsupported = false,
  }) : this(
         codePage: PrinterCodePage.cp866,
         country: 'CP866',
         sendCountryCommand: sendCountryCommand,
         replaceUnsupported: replaceUnsupported,
       );

  /// Standard CP857 (Turkish) mode.
  const CpclEncoding.cp857({
    bool sendCountryCommand = true,
    bool replaceUnsupported = false,
  }) : this(
         codePage: PrinterCodePage.cp857,
         country: 'CP857',
         sendCountryCommand: sendCountryCommand,
         replaceUnsupported: replaceUnsupported,
       );

  /// Custom CPCL encoding configuration.
  const CpclEncoding.custom({
    required PrinterCodePage codePage,
    String? country,
    bool sendCountryCommand = true,
    bool replaceUnsupported = false,
  }) : this(
         codePage: codePage,
         country: country,
         sendCountryCommand: sendCountryCommand,
         replaceUnsupported: replaceUnsupported,
       );

  /// The canonical default CPCL encoding (legacy CP437 without COUNTRY command).
  static const CpclEncoding defaultEncoding = CpclEncoding.legacy();
}

/// Explicit DPL character encoding configuration.
class DplEncoding {
  /// The character mapping to use for user text.
  final PrinterCodePage codePage;

  /// Whether to replace unencodable characters with `?` (0x3F) instead of throwing.
  final bool replaceUnsupported;

  const DplEncoding({required this.codePage, this.replaceUnsupported = false});

  /// Default legacy DPL mode (CP437 character mapping).
  const DplEncoding.legacy({bool replaceUnsupported = false})
    : this(
        codePage: PrinterCodePage.cp437,
        replaceUnsupported: replaceUnsupported,
      );

  /// Standard CP437 mode.
  const DplEncoding.cp437({bool replaceUnsupported = false})
    : this(
        codePage: PrinterCodePage.cp437,
        replaceUnsupported: replaceUnsupported,
      );

  /// Standard CP850 mode.
  const DplEncoding.cp850({bool replaceUnsupported = false})
    : this(
        codePage: PrinterCodePage.cp850,
        replaceUnsupported: replaceUnsupported,
      );

  /// Standard Windows CP1252 mode.
  const DplEncoding.cp1252({bool replaceUnsupported = false})
    : this(
        codePage: PrinterCodePage.cp1252,
        replaceUnsupported: replaceUnsupported,
      );

  /// Custom DPL encoding configuration.
  const DplEncoding.custom({
    required PrinterCodePage codePage,
    bool replaceUnsupported = false,
  }) : this(codePage: codePage, replaceUnsupported: replaceUnsupported);

  /// The canonical default DPL encoding (legacy CP437).
  static const DplEncoding defaultEncoding = DplEncoding.legacy();
}

/// Explicit IPL character encoding configuration.
class IplEncoding {
  /// The character mapping to use for user text.
  final PrinterCodePage codePage;

  /// Whether to replace unencodable or dangerous control characters with `?` (0x3F) instead of throwing.
  final bool replaceUnsupported;

  const IplEncoding({required this.codePage, this.replaceUnsupported = false});

  /// Default legacy IPL mode (CP437 character mapping).
  const IplEncoding.legacy({bool replaceUnsupported = false})
    : this(
        codePage: PrinterCodePage.cp437,
        replaceUnsupported: replaceUnsupported,
      );

  /// Standard CP437 mode.
  const IplEncoding.cp437({bool replaceUnsupported = false})
    : this(
        codePage: PrinterCodePage.cp437,
        replaceUnsupported: replaceUnsupported,
      );

  /// Standard CP850 mode.
  const IplEncoding.cp850({bool replaceUnsupported = false})
    : this(
        codePage: PrinterCodePage.cp850,
        replaceUnsupported: replaceUnsupported,
      );

  /// Standard Windows CP1252 mode.
  const IplEncoding.cp1252({bool replaceUnsupported = false})
    : this(
        codePage: PrinterCodePage.cp1252,
        replaceUnsupported: replaceUnsupported,
      );

  /// Custom IPL encoding configuration.
  const IplEncoding.custom({
    required PrinterCodePage codePage,
    bool replaceUnsupported = false,
  }) : this(codePage: codePage, replaceUnsupported: replaceUnsupported);

  /// The canonical default IPL encoding (legacy CP437).
  static const IplEncoding defaultEncoding = IplEncoding.legacy();
}

/// Explicit SBPL character encoding configuration.
class SbplEncoding {
  /// The character mapping to use for user text.
  final PrinterCodePage codePage;

  /// Whether to replace unencodable or control characters with `?` (0x3F) instead of throwing.
  final bool replaceUnsupported;

  const SbplEncoding({required this.codePage, this.replaceUnsupported = false});

  /// Default legacy SBPL mode (CP437 character mapping).
  const SbplEncoding.legacy({bool replaceUnsupported = false})
    : this(
        codePage: PrinterCodePage.cp437,
        replaceUnsupported: replaceUnsupported,
      );

  /// Standard CP437 mode.
  const SbplEncoding.cp437({bool replaceUnsupported = false})
    : this(
        codePage: PrinterCodePage.cp437,
        replaceUnsupported: replaceUnsupported,
      );

  /// Standard CP850 mode.
  const SbplEncoding.cp850({bool replaceUnsupported = false})
    : this(
        codePage: PrinterCodePage.cp850,
        replaceUnsupported: replaceUnsupported,
      );

  /// Standard Windows CP1252 mode.
  const SbplEncoding.cp1252({bool replaceUnsupported = false})
    : this(
        codePage: PrinterCodePage.cp1252,
        replaceUnsupported: replaceUnsupported,
      );

  /// Custom SBPL encoding configuration.
  const SbplEncoding.custom({
    required PrinterCodePage codePage,
    bool replaceUnsupported = false,
  }) : this(codePage: codePage, replaceUnsupported: replaceUnsupported);

  /// The canonical default SBPL encoding (legacy CP437).
  static const SbplEncoding defaultEncoding = SbplEncoding.legacy();
}

/// Explicit Star PRNT character encoding and code page selection configuration.
class StarPrntEncoding {
  /// The character mapping to use for user text.
  final PrinterCodePage codePage;

  /// The Star code page selector table number (e.g. 0 for CP437, 3 for CP858, 16 for CP1252).
  /// If null or sendCodePageCommand is false, no ESC GS t command is emitted.
  final int? characterTable;

  /// Whether to emit `ESC GS t <characterTable>` command in preamble.
  final bool sendCodePageCommand;

  /// Whether to replace unencodable characters with `?` (0x3F) instead of throwing.
  final bool replaceUnsupported;

  const StarPrntEncoding({
    required this.codePage,
    this.characterTable,
    this.sendCodePageCommand = false,
    this.replaceUnsupported = false,
  });

  /// Default legacy Star PRNT mode (CP437 mapping without code page command).
  const StarPrntEncoding.legacy({bool replaceUnsupported = false})
    : this(
        codePage: PrinterCodePage.cp437,
        characterTable: null,
        sendCodePageCommand: false,
        replaceUnsupported: replaceUnsupported,
      );

  /// Standard CP437 mode.
  const StarPrntEncoding.cp437({
    bool sendCodePageCommand = false,
    bool replaceUnsupported = false,
  }) : this(
         codePage: PrinterCodePage.cp437,
         characterTable: 0,
         sendCodePageCommand: sendCodePageCommand,
         replaceUnsupported: replaceUnsupported,
       );

  /// Standard CP858 (Western European with Euro) mode.
  const StarPrntEncoding.cp858({
    bool sendCodePageCommand = true,
    bool replaceUnsupported = false,
  }) : this(
         codePage: PrinterCodePage.cp858,
         characterTable: 3,
         sendCodePageCommand: sendCodePageCommand,
         replaceUnsupported: replaceUnsupported,
       );

  /// Standard CP850 (Western European) mode.
  const StarPrntEncoding.cp850({
    bool sendCodePageCommand = true,
    bool replaceUnsupported = false,
  }) : this(
         codePage: PrinterCodePage.cp850,
         characterTable: 1,
         sendCodePageCommand: sendCodePageCommand,
         replaceUnsupported: replaceUnsupported,
       );

  /// Standard Windows CP1252 mode.
  const StarPrntEncoding.cp1252({
    bool sendCodePageCommand = true,
    bool replaceUnsupported = false,
  }) : this(
         codePage: PrinterCodePage.cp1252,
         characterTable: 16,
         sendCodePageCommand: sendCodePageCommand,
         replaceUnsupported: replaceUnsupported,
       );

  /// Custom Star PRNT encoding configuration.
  const StarPrntEncoding.custom({
    required PrinterCodePage codePage,
    int? characterTable,
    bool sendCodePageCommand = true,
    bool replaceUnsupported = false,
  }) : this(
         codePage: codePage,
         characterTable: characterTable,
         sendCodePageCommand: sendCodePageCommand,
         replaceUnsupported: replaceUnsupported,
       );

  /// The canonical default Star PRNT encoding (legacy CP437).
  static const StarPrntEncoding defaultEncoding = StarPrntEncoding.legacy();
}

/// Character encoder for a single [PrinterCodePage].
class CodePageEncoder {
  final PrinterCodePage codePage;
  final Map<int, int> _charMap;

  const CodePageEncoder._(this.codePage, this._charMap);

  /// Encodes [text] into an 8-bit byte sequence.
  ///
  /// If [replaceUnsupported] is false (default), throws [UnsupportedCharacterException]
  /// upon encountering any character not representable in this code page.
  /// If true, unencodable characters are replaced with [replacement] (default: `?` / 0x3F).
  Uint8List encode(
    String text, {
    bool replaceUnsupported = false,
    int replacement = 0x3F,
  }) {
    final bytes = <int>[];

    for (final rune in text.runes) {
      // Direct ASCII pass-through (printable characters, LF, CR, TAB)
      if ((rune >= 0x20 && rune <= 0x7E) ||
          rune == 0x0A ||
          rune == 0x0D ||
          rune == 0x09) {
        bytes.add(rune);
      } else {
        final mapped = _charMap[rune];
        if (mapped != null) {
          bytes.add(mapped);
        } else if (replaceUnsupported) {
          bytes.add(replacement);
        } else {
          throw UnsupportedCharacterException(
            character: String.fromCharCode(rune),
            codePoint: rune,
            codePage: codePage,
          );
        }
      }
    }

    return Uint8List.fromList(bytes);
  }

  /// Whether all characters in [text] can be encoded in this code page.
  bool canEncode(String text) {
    for (final rune in text.runes) {
      if ((rune >= 0x20 && rune <= 0x7E) ||
          rune == 0x0A ||
          rune == 0x0D ||
          rune == 0x09) {
        continue;
      }
      if (!_charMap.containsKey(rune)) {
        return false;
      }
    }
    return true;
  }
}

// -----------------------------------------------------------------------------
// Character Mapping Tables
// -----------------------------------------------------------------------------

// CP437 — IBM PC / US
final Map<int, int> _cp437Map = {
  0x00C7: 0x80, // Ç
  0x00FC: 0x81, // ü
  0x00E9: 0x82, // é
  0x00E2: 0x83, // â
  0x00E4: 0x84, // ä
  0x00E0: 0x85, // à
  0x00E5: 0x86, // å
  0x00E7: 0x87, // ç
  0x00EA: 0x88, // ê
  0x00EB: 0x89, // ë
  0x00E8: 0x8A, // è
  0x00EF: 0x8B, // ï
  0x00EE: 0x8C, // î
  0x00EC: 0x8D, // ì
  0x00C4: 0x8E, // Ä
  0x00C5: 0x8F, // Å
  0x00C9: 0x90, // É
  0x00E6: 0x91, // æ
  0x00C6: 0x92, // Æ
  0x00F4: 0x93, // ô
  0x00F6: 0x94, // ö
  0x00F2: 0x95, // ò
  0x00FB: 0x96, // û
  0x00F9: 0x97, // ù
  0x00FF: 0x98, // ÿ
  0x00D6: 0x99, // Ö
  0x00DC: 0x9A, // Ü
  0x00A2: 0x9B, // ¢
  0x00A3: 0x9C, // £
  0x00A5: 0x9D, // ¥
  0x00DF: 0xE1, // ß
  0x00B5: 0xE6, // µ
  0x00F1: 0xA4, // ñ
  0x00D1: 0xA5, // Ñ
  0x00AA: 0xA6, // ª
  0x00BA: 0xA7, // º
  0x00BF: 0xA8, // ¿
  0x00A1: 0xAD, // ¡
  0x00AB: 0xAE, // «
  0x00BB: 0xAF, // »
  0x00BD: 0xAB, // ½
  0x00BC: 0xAC, // ¼
  0x00B0: 0xF8, // °
  0x00B1: 0xF1, // ±
  0x00B2: 0xFD, // ²
};

// CP850 — Multilingual Latin I
final Map<int, int> _cp850Map = {
  ..._cp437Map,
  0x00E1: 0xA0, // á
  0x00ED: 0xA1, // í
  0x00F3: 0xA2, // ó
  0x00FA: 0xA3, // ú
  0x00C1: 0xB5, // Á
  0x00CD: 0xD6, // Í
  0x00D3: 0xE0, // Ó
  0x00DA: 0xE9, // Ú
  0x00C0: 0xB7, // À
  0x00C8: 0xD4, // È
  0x00CC: 0xDE, // Ì
  0x00D2: 0xE3, // Ò
  0x00D9: 0xEB, // Ù
};

// CP858 — Western European with Euro sign (€)
final Map<int, int> _cp858Map = {
  ..._cp850Map,
  0x20AC: 0xD5, // € Euro sign
};

// CP1252 — Windows Western
final Map<int, int> _cp1252Map = {
  0x20AC: 0x80, // €
  0x201A: 0x82, // ‚
  0x0192: 0x83, // ƒ
  0x201E: 0x84, // „
  0x2026: 0x85, // …
  0x2020: 0x86, // †
  0x2021: 0x87, // ‡
  0x02C6: 0x88, // ˆ
  0x2030: 0x89, // ‰
  0x0160: 0x8A, // Š
  0x2039: 0x8B, // ‹
  0x0152: 0x8C, // Œ
  0x017D: 0x8E, // Ž
  0x2018: 0x91, // ‘
  0x2019: 0x92, // ’
  0x201C: 0x93, // “
  0x201D: 0x94, // ”
  0x2022: 0x95, // •
  0x2013: 0x96, // –
  0x2014: 0x97, // —
  0x02DC: 0x98, // ˜
  0x2122: 0x99, // ™
  0x0161: 0x9A, // š
  0x203A: 0x9B, // ›
  0x0153: 0x9C, // œ
  0x017E: 0x9E, // ž
  0x0178: 0x9F, // Ÿ
  // ISO-8859-1 direct mapping (0xA0..0xFF)
  for (int i = 0xA0; i <= 0xFF; i++) i: i,
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
  // Common Cyrillic extras
  m[0x0401] = 0xF0; // Ё
  m[0x0451] = 0xF1; // ё
  m[0x0404] = 0xF2; // Є
  m[0x0454] = 0xF3; // є
  m[0x0407] = 0xF4; // Ї
  m[0x0457] = 0xF5; // ї
  m[0x040E] = 0xF6; // Ў
  m[0x045E] = 0xF7; // ў
  m[0x00B0] = 0xF8; // °
  m[0x2219] = 0xF9; // ∙
  m[0x221A] = 0xFB; // √
  m[0x00A0] = 0xFF; // NBSP
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

/// Encoders cached by [PrinterCodePage].
final Map<PrinterCodePage, CodePageEncoder> _encoders = {
  PrinterCodePage.cp437: CodePageEncoder._(PrinterCodePage.cp437, _cp437Map),
  PrinterCodePage.cp858: CodePageEncoder._(PrinterCodePage.cp858, _cp858Map),
  PrinterCodePage.cp850: CodePageEncoder._(PrinterCodePage.cp850, _cp850Map),
  PrinterCodePage.cp1252: CodePageEncoder._(PrinterCodePage.cp1252, _cp1252Map),
  PrinterCodePage.cp866: CodePageEncoder._(PrinterCodePage.cp866, _cp866Map),
  PrinterCodePage.cp857: CodePageEncoder._(PrinterCodePage.cp857, _cp857Map),
};

/// Get the [CodePageEncoder] for the given [codePage].
CodePageEncoder getEncoder(PrinterCodePage codePage) {
  return _encoders[codePage]!;
}

// -----------------------------------------------------------------------------
// Legacy / Compatibility Helpers (Preserved for compatibility)
// -----------------------------------------------------------------------------

/// A segment of encoded text with its code page.
class EncodedSegment {
  final int codePage; // -1 = ASCII (no switch needed)
  final Uint8List data;

  const EncodedSegment({required this.codePage, required this.data});
}

/// Code page definition.
class CodePage {
  final int escPosId;
  final Map<int, int> charMap;

  const CodePage({required this.escPosId, required this.charMap});
}

final List<CodePage> _legacyCodePages = [
  CodePage(escPosId: 0, charMap: _cp437Map),
  CodePage(escPosId: 19, charMap: _cp858Map),
  CodePage(escPosId: 16, charMap: _cp1252Map),
  CodePage(escPosId: 17, charMap: _cp866Map),
  CodePage(escPosId: 13, charMap: _cp857Map),
];

/// Check if a string contains only ASCII printable characters + newlines.
bool isASCII(String text) {
  for (final rune in text.runes) {
    if (rune == 0x0A || rune == 0x0D || rune == 0x09) continue;
    if (rune < 0x20 || rune > 0x7E) return false;
  }
  return true;
}

(int, int)? _findLegacyCodePage(int codepoint) {
  for (final cp in _legacyCodePages) {
    final byte = cp.charMap[codepoint];
    if (byte != null) return (cp.escPosId, byte);
  }
  return null;
}

/// Encode text into segments with code page information.
List<EncodedSegment> encodeText(String text) {
  if (text.isEmpty) return [];

  final segments = <EncodedSegment>[];
  int currentCodePage = -1;
  final currentBytes = <int>[];

  void flushSegment() {
    if (currentBytes.isNotEmpty) {
      segments.add(
        EncodedSegment(
          codePage: currentCodePage,
          data: Uint8List.fromList(currentBytes),
        ),
      );
      currentBytes.clear();
    }
  }

  for (final rune in text.runes) {
    if (rune >= 0x20 && rune <= 0x7E || rune == 0x0A || rune == 0x0D) {
      if (currentCodePage != -1) {
        flushSegment();
        currentCodePage = -1;
      }
      currentBytes.add(rune);
    } else {
      final result = _findLegacyCodePage(rune);
      if (result != null) {
        final (cpId, byteVal) = result;
        if (currentCodePage != cpId) {
          flushSegment();
          currentCodePage = cpId;
        }
        currentBytes.add(byteVal);
      } else {
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
Uint8List encodeTextForPrinter(String text) {
  final segments = encodeText(text);
  final bytes = <int>[];

  for (final seg in segments) {
    if (seg.codePage >= 0) {
      bytes.addAll([0x1B, 0x74, seg.codePage]);
    }
    bytes.addAll(seg.data);
  }

  return Uint8List.fromList(bytes);
}
