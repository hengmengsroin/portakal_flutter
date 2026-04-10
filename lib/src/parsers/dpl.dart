import '../types.dart';

class DPLCommand {
  final String type;
  final String params;
  DPLCommand({required this.type, this.params = ''});
}

class DPLParseResult {
  final List<DPLCommand> commands;
  final List<LabelElement> elements;
  int widthDots;
  DPLParseResult({
    required this.commands,
    required this.elements,
    this.widthDots = 0,
  });
}

DPLParseResult parseDPL(String code) {
  final commands = <DPLCommand>[];
  final elements = <LabelElement>[];
  int widthDots = 0;

  for (final line in code.split(RegExp(r'\r?\n'))) {
    final l = line.trim();
    if (l.isEmpty) continue;

    if (l == '\x02L' || l.startsWith('\x02L')) {
      commands.add(DPLCommand(type: 'STX_L'));
    } else if (l == 'E') {
      commands.add(DPLCommand(type: 'E'));
    } else if (l.startsWith('D')) {
      commands.add(DPLCommand(type: 'DENSITY', params: l.substring(1)));
    } else if (l.startsWith('S') && l.length <= 4) {
      commands.add(DPLCommand(type: 'SPEED', params: l.substring(1)));
    } else if (l.startsWith('A')) {
      widthDots = int.tryParse(l.substring(1)) ?? widthDots;
      commands.add(DPLCommand(type: 'WIDTH', params: l.substring(1)));
    } else if (l.startsWith('Q')) {
      commands.add(DPLCommand(type: 'QUANTITY', params: l.substring(1)));
    }
  }

  return DPLParseResult(
    commands: commands,
    elements: elements,
    widthDots: widthDots,
  );
}
