import 'dart:typed_data';
import '../types.dart';

/// Parsed ESC/POS command.
class ESCPOSCommand {
  final String name;
  final Map<String, dynamic> params;
  ESCPOSCommand({required this.name, this.params = const {}});
}

/// Result of parsing ESC/POS binary data.
class ESCPOSParseResult {
  final List<ESCPOSCommand> commands;
  final List<LabelElement> elements;
  ESCPOSParseResult({required this.commands, required this.elements});
}

/// Parse ESC/POS binary data.
ESCPOSParseResult parseESCPOS(Uint8List data) {
  final commands = <ESCPOSCommand>[];
  final elements = <LabelElement>[];
  int i = 0;
  // State
  String? currentAlign;
  bool boldOn = false;
  int widthScale = 1, heightScale = 1;

  while (i < data.length) {
    // DLE EOT (0x10 0x04)
    if (data[i] == 0x10 && i + 2 < data.length && data[i + 1] == 0x04) {
      commands.add(
        ESCPOSCommand(name: 'DLE EOT', params: {'type': data[i + 2]}),
      );
      i += 3;
      continue;
    }

    // ESC commands (0x1B)
    if (data[i] == 0x1B && i + 1 < data.length) {
      final next = data[i + 1];
      switch (next) {
        case 0x40: // ESC @
          commands.add(ESCPOSCommand(name: 'ESC @'));
          i += 2;
          continue;
        case 0x61: // ESC a (alignment)
          if (i + 2 < data.length) {
            final n = data[i + 2];
            final align = n == 0
                ? 'left'
                : n == 1
                    ? 'center'
                    : 'right';
            commands.add(
              ESCPOSCommand(name: 'ESC a', params: {'align': align}),
            );
            currentAlign = align;
          }
          i += 3;
          continue;
        case 0x45: // ESC E (bold)
          if (i + 2 < data.length) {
            boldOn = data[i + 2] != 0;
            commands.add(
              ESCPOSCommand(name: 'ESC E', params: {'bold': boldOn}),
            );
          }
          i += 3;
          continue;
        case 0x74: // ESC t (code page)
          if (i + 2 < data.length) {
            commands.add(
              ESCPOSCommand(name: 'ESC t', params: {'codePage': data[i + 2]}),
            );
          }
          i += 3;
          continue;
        case 0x70: // ESC p (cash drawer)
          if (i + 4 < data.length) {
            commands.add(
              ESCPOSCommand(
                name: 'ESC p',
                params: {
                  'pin': data[i + 2],
                  't1': data[i + 3],
                  't2': data[i + 4],
                },
              ),
            );
          }
          i += 5;
          continue;
      }
    }

    // GS commands (0x1D)
    if (data[i] == 0x1D && i + 1 < data.length) {
      final next = data[i + 1];
      switch (next) {
        case 0x21: // GS ! (character size)
          if (i + 2 < data.length) {
            final n = data[i + 2];
            widthScale = ((n >> 4) & 0x0F) + 1;
            heightScale = (n & 0x0F) + 1;
            commands.add(
              ESCPOSCommand(
                name: 'GS !',
                params: {'width': widthScale, 'height': heightScale},
              ),
            );
          }
          i += 3;
          continue;
        case 0x56: // GS V (cut)
          if (i + 3 < data.length) {
            commands.add(
              ESCPOSCommand(
                name: 'GS V',
                params: {'mode': data[i + 2], 'feed': data[i + 3]},
              ),
            );
            i += 4;
          } else {
            commands.add(
              ESCPOSCommand(
                name: 'GS V',
                params: {'mode': i + 2 < data.length ? data[i + 2] : 0},
              ),
            );
            i += 3;
          }
          continue;
        case 0x6B: // GS k (barcode)
          if (i + 3 < data.length) {
            final type = data[i + 2];
            final len = data[i + 3];
            if (i + 4 + len <= data.length) {
              final bcData = String.fromCharCodes(
                data.sublist(i + 4, i + 4 + len),
              );
              commands.add(
                ESCPOSCommand(
                  name: 'GS k',
                  params: {'type': type, 'data': bcData},
                ),
              );
              i += 4 + len;
            } else {
              i += 4;
            }
          } else {
            i += 2;
          }
          continue;
        case 0x76: // GS v 0 (raster image)
          if (i + 7 < data.length && data[i + 2] == 0x30) {
            final mode = data[i + 3];
            final bytesPerRow = data[i + 4] | (data[i + 5] << 8);
            final rows = data[i + 6] | (data[i + 7] << 8);
            commands.add(
              ESCPOSCommand(
                name: 'GS v 0',
                params: {
                  'mode': mode,
                  'bytesPerRow': bytesPerRow,
                  'rows': rows,
                },
              ),
            );
            i += 8 + bytesPerRow * rows;
          } else {
            i += 2;
          }
          continue;
      }
    }

    // Regular text byte
    if (data[i] >= 0x20 && data[i] <= 0x7E) {
      final start = i;
      while (i < data.length && data[i] >= 0x20 && data[i] <= 0x7E) {
        i++;
      }
      final text = String.fromCharCodes(data.sublist(start, i));
      elements.add(
        TextElement(
          content: text,
          options: TextOptions(align: currentAlign, bold: boldOn ? true : null),
        ),
      );
      continue;
    }

    i++;
  }

  return ESCPOSParseResult(commands: commands, elements: elements);
}
