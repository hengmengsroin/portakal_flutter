import 'dart:typed_data';
import '../types.dart';

class StarPRNTCommand {
  final String name;
  final Map<String, dynamic> params;
  StarPRNTCommand({required this.name, this.params = const {}});
}

class StarPRNTParseResult {
  final List<StarPRNTCommand> commands;
  final List<LabelElement> elements;
  StarPRNTParseResult({required this.commands, required this.elements});
}

StarPRNTParseResult parseStarPRNT(Uint8List data) {
  final commands = <StarPRNTCommand>[];
  final elements = <LabelElement>[];
  int i = 0;
  bool boldOn = false;

  while (i < data.length) {
    // BEL (0x07)
    if (data[i] == 0x07) {
      commands.add(StarPRNTCommand(name: 'BEL'));
      i++;
      continue;
    }

    // ESC commands
    if (data[i] == 0x1B && i + 1 < data.length) {
      switch (data[i + 1]) {
        case 0x40: // ESC @
          commands.add(StarPRNTCommand(name: 'ESC @'));
          i += 2;
          continue;
        case 0x45: // ESC E (bold on)
          commands.add(StarPRNTCommand(name: 'ESC E'));
          boldOn = true;
          i += 2;
          continue;
        case 0x46: // ESC F (bold off)
          commands.add(StarPRNTCommand(name: 'ESC F'));
          boldOn = false;
          i += 2;
          continue;
        case 0x64: // ESC d (partial cut)
          if (i + 2 < data.length) {
            commands.add(StarPRNTCommand(name: 'ESC d', params: {'n': data[i + 2]}));
          }
          i += 3;
          continue;
        case 0x69: // ESC i (size)
          if (i + 3 < data.length) {
            commands.add(StarPRNTCommand(name: 'ESC i', params: {
              'height': data[i + 2],
              'width': data[i + 3],
            }));
          }
          i += 4;
          continue;
        case 0x1D: // ESC GS
          if (i + 3 < data.length && data[i + 2] == 0x61) {
            commands.add(StarPRNTCommand(name: 'ESC GS a', params: {'n': data[i + 3]}));
            i += 4;
            continue;
          }
          i += 2;
          continue;
        case 0x2A: // ESC * (raster)
          if (i + 3 < data.length && data[i + 2] == 0x72) {
            if (data[i + 3] == 0x41) {
              commands.add(StarPRNTCommand(name: 'ESC * r A'));
              i += 4;
              // Parse raster rows until ESC * r B
              while (i < data.length) {
                if (data[i] == 0x1B && i + 3 < data.length &&
                    data[i + 1] == 0x2A && data[i + 2] == 0x72 && data[i + 3] == 0x42) {
                  commands.add(StarPRNTCommand(name: 'ESC * r B'));
                  i += 4;
                  break;
                }
                if (data[i] == 0x62) { // b command
                  if (i + 2 < data.length) {
                    final n = data[i + 1] | (data[i + 2] << 8);
                    i += 3 + n;
                  } else {
                    i++;
                  }
                } else {
                  i++;
                }
              }
              continue;
            } else if (data[i + 3] == 0x42) {
              commands.add(StarPRNTCommand(name: 'ESC * r B'));
              i += 4;
              continue;
            }
          }
          i += 2;
          continue;
      }
    }

    // Text
    if (data[i] >= 0x20 && data[i] <= 0x7E) {
      final start = i;
      while (i < data.length && data[i] >= 0x20 && data[i] <= 0x7E) i++;
      final text = String.fromCharCodes(data.sublist(start, i));
      elements.add(TextElement(
        content: text,
        options: TextOptions(bold: boldOn ? true : null),
      ));
      commands.add(StarPRNTCommand(name: 'TEXT', params: {'text': text}));
      continue;
    }

    i++;
  }

  return StarPRNTParseResult(commands: commands, elements: elements);
}
