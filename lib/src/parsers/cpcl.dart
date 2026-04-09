import '../types.dart';

/// Result of parsing CPCL code.
class CPCLParseResult {
  final List<LabelElement> elements;
  int widthDots;
  int heightDots;
  int dpi;

  CPCLParseResult({
    required this.elements,
    this.widthDots = 0,
    this.heightDots = 0,
    this.dpi = 200,
  });
}

/// Parse CPCL code.
CPCLParseResult parseCPCL(String code) {
  final lines = code.split(RegExp(r'\r?\n'));
  final elements = <LabelElement>[];
  int widthDots = 0;
  int heightDots = 0;
  int dpi = 200;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;

    // Session header: ! offset hDPI vDPI height qty
    if (line.startsWith('! ')) {
      final p = line.substring(2).split(RegExp(r'\s+'));
      if (p.length >= 4) {
        dpi = int.tryParse(p[1]) ?? 200;
        heightDots = int.tryParse(p[3]) ?? 0;
      }
      continue;
    }

    if (line.startsWith('PAGE-WIDTH')) {
      widthDots = int.tryParse(line.split(RegExp(r'\s+'))[1]) ?? 0;
      continue;
    }

    // TEXT font size x y  (content on next line)
    final textMatch = RegExp(r'^(TEXT(?:90|180|270)?)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)$').firstMatch(line);
    if (textMatch != null) {
      final nextLine = (i + 1 < lines.length) ? lines[i + 1].trim() : '';
      i++; // consume next line
      elements.add(TextElement(
        content: nextLine,
        options: TextOptions(
          x: int.parse(textMatch.group(4)!),
          y: int.parse(textMatch.group(5)!),
          font: textMatch.group(2),
        ),
      ));
      continue;
    }

    // BOX x1 y1 x2 y2 thickness
    if (line.startsWith('BOX ')) {
      final p = line.substring(4).split(RegExp(r'\s+'));
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
      continue;
    }

    // LINE x1 y1 x2 y2 thickness
    if (line.startsWith('LINE ')) {
      final p = line.substring(5).split(RegExp(r'\s+'));
      if (p.length >= 5) {
        elements.add(LineElement(
          options: LineOptions(
            x1: int.tryParse(p[0]) ?? 0,
            y1: int.tryParse(p[1]) ?? 0,
            x2: int.tryParse(p[2]) ?? 0,
            y2: int.tryParse(p[3]) ?? 0,
            thickness: int.tryParse(p[4]),
          ),
        ));
      }
    }
  }

  return CPCLParseResult(
    elements: elements,
    widthDots: widthDots,
    heightDots: heightDots,
    dpi: dpi,
  );
}
