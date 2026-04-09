import '../types.dart';

/// Result of parsing ZPL code.
class ZPLParseResult {
  final List<ZPLCommand> commands;
  final List<LabelElement> elements;
  final int widthDots;
  final int heightDots;
  final List<String> warnings;

  ZPLParseResult({
    required this.commands,
    required this.elements,
    this.widthDots = 812,
    this.heightDots = 1218,
    this.warnings = const [],
  });
}

/// A parsed ZPL command.
class ZPLCommand {
  final String code;
  final List<String> params;
  final String rawParams;

  ZPLCommand({required this.code, this.params = const [], this.rawParams = ''});
}

/// Parse ZPL code.
ZPLParseResult parseZPL(String code) {
  if (code.trim().isEmpty) {
    return ZPLParseResult(commands: [], elements: []);
  }

  final commands = _tokenize(code);
  int widthDots = 812; // default 4-inch at 203 DPI
  int heightDots = 1218; // default 6-inch at 203 DPI
  final elements = <LabelElement>[];

  // State for field assembly
  int curX = 0, curY = 0;

  bool fieldReverse = false;

  for (int i = 0; i < commands.length; i++) {
    final cmd = commands[i];

    switch (cmd.code) {
      case '^PW':
        widthDots = int.tryParse(cmd.params.isNotEmpty ? cmd.params[0] : '') ?? widthDots;
      case '^LL':
        heightDots = int.tryParse(cmd.params.isNotEmpty ? cmd.params[0] : '') ?? heightDots;
      case '^FO':
        curX = int.tryParse(cmd.params.isNotEmpty ? cmd.params[0] : '') ?? 0;
        curY = int.tryParse(cmd.params.length > 1 ? cmd.params[1] : '') ?? 0;
        fieldReverse = false;
      case '^A0':
      case '^A':
        // Font state parsed but not used for element construction
        break;
      case '^FR':
        fieldReverse = true;
      case '^FD':
        elements.add(TextElement(
          content: cmd.rawParams,
          options: TextOptions(
            x: curX,
            y: curY,
            reverse: fieldReverse ? true : null,
          ),
        ));
        fieldReverse = false;
      case '^GB':
        final p = cmd.params;
        final w = int.tryParse(p.isNotEmpty ? p[0] : '') ?? 0;
        final h = int.tryParse(p.length > 1 ? p[1] : '') ?? 0;
        final t = int.tryParse(p.length > 2 ? p[2] : '') ?? 1;
        final roundIdx = int.tryParse(p.length > 4 ? p[4] : '') ?? 0;
        int? radius;
        if (roundIdx > 0) {
          final minSide = w < h ? w : h;
          radius = (roundIdx / 8 * minSide / 2).round();
        }
        elements.add(BoxElement(
          options: BoxOptions(
            x: curX,
            y: curY,
            width: w,
            height: h,
            thickness: t,
            radius: radius,
          ),
        ));
      case '^GC':
        final p = cmd.params;
        final diameter = int.tryParse(p.isNotEmpty ? p[0] : '') ?? 0;
        final thickness = int.tryParse(p.length > 1 ? p[1] : '') ?? 1;
        elements.add(CircleElement(
          options: CircleOptions(
            x: curX,
            y: curY,
            diameter: diameter,
            thickness: thickness,
          ),
        ));
      case '^GD':
        final p = cmd.params;
        final w = int.tryParse(p.isNotEmpty ? p[0] : '') ?? 0;
        final h = int.tryParse(p.length > 1 ? p[1] : '') ?? 0;
        final t = int.tryParse(p.length > 2 ? p[2] : '') ?? 1;
        final dir = p.length > 4 ? p[4] : 'R';
        if (dir == 'R') {
          elements.add(LineElement(
            options: LineOptions(
              x1: curX,
              y1: curY,
              x2: curX + w,
              y2: curY + h,
              thickness: t,
            ),
          ));
        } else {
          elements.add(LineElement(
            options: LineOptions(
              x1: curX + w,
              y1: curY,
              x2: curX,
              y2: curY + h,
              thickness: t,
            ),
          ));
        }
    }
  }

  return ZPLParseResult(
    commands: commands,
    elements: elements,
    widthDots: widthDots,
    heightDots: heightDots,
  );
}

/// Tokenize ZPL code into commands.
List<ZPLCommand> _tokenize(String code) {
  final commands = <ZPLCommand>[];
  final flat = code.replaceAll(RegExp(r'\r?\n'), '');
  int i = 0;

  while (i < flat.length) {
    // Skip whitespace
    while (i < flat.length && flat[i] == ' ') {
      i++;
    }
    if (i >= flat.length) break;

    // Command start: ^ or ~
    if (flat[i] == '^' || flat[i] == '~') {
      final prefix = flat[i];
      i++;
      if (i >= flat.length) break;

      // Read command code (2 chars usually)
      String cmdCode = prefix;
      if (i < flat.length) {
        cmdCode += flat[i];
        i++;
      }
      if (i < flat.length && flat[i] != '^' && flat[i] != '~') {
        // Check for 2-char command
        if (cmdCode == '^F' || cmdCode == '^A' || cmdCode == '^G' ||
            cmdCode == '^B' || cmdCode == '^P' || cmdCode == '^L' ||
            cmdCode == '^C' || cmdCode == '~S' || cmdCode == '^X' ||
            cmdCode == '^M') {
          cmdCode += flat[i];
          i++;
        }
      }

      // Special handling for ^FD — read until ^FS
      if (cmdCode == '^FD') {
        final fdStart = i;
        while (i < flat.length) {
          if (flat[i] == '^' && i + 2 < flat.length && flat[i + 1] == 'F' && flat[i + 2] == 'S') {
            break;
          }
          i++;
        }
        final fdContent = flat.substring(fdStart, i);
        commands.add(ZPLCommand(code: cmdCode, rawParams: fdContent));
        // Skip ^FS
        if (i < flat.length && flat[i] == '^') {
          commands.add(ZPLCommand(code: '^FS'));
          i += 3;
        }
        continue;
      }

      // Special handling for ^FX comments — read until next ^
      if (cmdCode == '^FX') {
        final fxStart = i;
        while (i < flat.length && flat[i] != '^' && flat[i] != '~') {
          i++;
        }
        commands.add(ZPLCommand(code: cmdCode, rawParams: flat.substring(fxStart, i).trim()));
        continue;
      }

      // Read until next ^ or ~ or end
      final paramStart = i;
      while (i < flat.length && flat[i] != '^' && flat[i] != '~') {
        i++;
      }
      final rawParams = flat.substring(paramStart, i).trim();
      final params = rawParams.isNotEmpty ? rawParams.split(',') : <String>[];
      commands.add(ZPLCommand(code: cmdCode, params: params, rawParams: rawParams));
    } else {
      i++;
    }
  }

  return commands;
}
