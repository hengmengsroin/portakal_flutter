import '../types.dart';

/// Result of parsing EPL code.
class EPLParseResult {
  final List<EPLCommand> commands;
  final List<LabelElement> elements;
  int widthDots;
  int heightDots;

  EPLParseResult({
    required this.commands,
    required this.elements,
    this.widthDots = 0,
    this.heightDots = 0,
  });
}

class EPLCommand {
  final String cmd;
  final String params;

  EPLCommand({required this.cmd, this.params = ''});
}

/// Parse EPL code.
EPLParseResult parseEPL(String code) {
  final commands = <EPLCommand>[];
  final elements = <LabelElement>[];
  int widthDots = 0;
  int heightDots = 0;

  for (final line in code.split(RegExp(r'\r?\n'))) {
    final l = line.trim();
    if (l.isEmpty) continue;

    final firstChar = l[0];
    final rest = l.length > 1 ? l.substring(1) : '';

    commands.add(EPLCommand(cmd: firstChar, params: rest));

    switch (firstChar) {
      case 'N':
        break;
      case 'q':
        widthDots = int.tryParse(rest) ?? 0;
      case 'Q':
        final p = rest.split(',');
        heightDots = int.tryParse(p[0]) ?? 0;
      case 'A':
        // A x,y,rotation,font,xmul,ymul,N/R,"text"
        final m = RegExp(r'^(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),([NR]),"([^"]*)"').firstMatch(rest);
        if (m != null) {
          elements.add(TextElement(
            content: m.group(8)!,
            options: TextOptions(
              x: int.parse(m.group(1)!),
              y: int.parse(m.group(2)!),
              rotation: int.parse(m.group(3)!) * 90,
              font: m.group(4),
              xScale: int.parse(m.group(5)!),
              yScale: int.parse(m.group(6)!),
              reverse: m.group(7) == 'R' ? true : null,
            ),
          ));
        }
      case 'X':
        // X x1,y1,x2,y2,thickness
        final p = rest.split(',');
        if (p.length >= 5) {
          final x1 = int.tryParse(p[0]) ?? 0;
          final y1 = int.tryParse(p[1]) ?? 0;
          final x2 = int.tryParse(p[2]) ?? 0;
          final y2 = int.tryParse(p[3]) ?? 0;
          elements.add(BoxElement(
            options: BoxOptions(
              x: x1,
              y: y1,
              width: x2 - x1,
              height: y2 - y1,
              thickness: int.tryParse(p[4]),
            ),
          ));
        }
      case 'L':
        if (rest.startsWith('O')) {
          // LO x,y,w,h
          final p = rest.substring(1).split(',');
          if (p.length >= 4) {
            elements.add(LineElement(
              options: LineOptions(
                x1: int.tryParse(p[0]) ?? 0,
                y1: int.tryParse(p[1]) ?? 0,
                x2: (int.tryParse(p[0]) ?? 0) + (int.tryParse(p[2]) ?? 0),
                y2: int.tryParse(p[1]) ?? 0,
                thickness: int.tryParse(p[3]),
              ),
            ));
          }
        }
    }
  }

  return EPLParseResult(
    commands: commands,
    elements: elements,
    widthDots: widthDots,
    heightDots: heightDots,
  );
}
