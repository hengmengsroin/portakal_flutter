import '../types.dart';

class SBPLCommand {
  final String cmd;
  final String params;
  SBPLCommand({required this.cmd, this.params = ''});
}

class SBPLParseResult {
  final List<SBPLCommand> commands;
  final List<LabelElement> elements;
  SBPLParseResult({required this.commands, required this.elements});
}

SBPLParseResult parseSBPL(String code) {
  final commands = <SBPLCommand>[];
  final elements = <LabelElement>[];
  int curX = 0, curY = 0;

  // Split on ESC (0x1B)
  int i = 0;
  while (i < code.length) {
    if (code.codeUnitAt(i) == 0x1B) {
      i++;
      if (i >= code.length) break;

      // Read command
      if (code[i] == 'A') {
        commands.add(SBPLCommand(cmd: 'START'));
        i++;
      } else if (code[i] == 'Z') {
        commands.add(SBPLCommand(cmd: 'END'));
        i++;
      } else if (code[i] == 'C' && i + 1 < code.length && code[i + 1] == 'S') {
        i += 2;
        final start = i;
        while (i < code.length && code.codeUnitAt(i) != 0x1B) {
          i++;
        }
        final params = code.substring(start, i);
        commands.add(SBPLCommand(cmd: 'CS', params: params));
      } else if (code[i] == 'H') {
        i++;
        final start = i;
        while (i < code.length && code.codeUnitAt(i) != 0x1B) {
          i++;
        }
        final params = code.substring(start, i);
        commands.add(SBPLCommand(cmd: 'H', params: params));
        curX = int.tryParse(params) ?? curX;
      } else if (code[i] == 'V') {
        i++;
        final start = i;
        while (i < code.length && code.codeUnitAt(i) != 0x1B) {
          i++;
        }
        final params = code.substring(start, i);
        commands.add(SBPLCommand(cmd: 'V', params: params));
        curY = int.tryParse(params) ?? curY;
      } else if (code[i] == 'K' &&
          i + 2 < code.length &&
          code[i + 1] == '9' &&
          code[i + 2] == 'B') {
        i += 3;
        final start = i;
        while (i < code.length && code.codeUnitAt(i) != 0x1B) {
          i++;
        }
        final text = code.substring(start, i);
        commands.add(SBPLCommand(cmd: 'K9B', params: text));
        elements.add(
          TextElement(
            content: text,
            options: TextOptions(x: curX, y: curY),
          ),
        );
      } else {
        // Skip other ESC commands
        i++;
        while (i < code.length && code.codeUnitAt(i) != 0x1B) {
          i++;
        }
      }
    } else {
      i++;
    }
  }

  return SBPLParseResult(commands: commands, elements: elements);
}
