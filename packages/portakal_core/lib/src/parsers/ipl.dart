import '../types.dart';

class IPLCommand {
  final String type;
  final String params;
  IPLCommand({required this.type, this.params = ''});
}

class IPLParseResult {
  final List<IPLCommand> commands;
  final List<LabelElement> elements;
  int widthDots;
  int heightDots;
  IPLParseResult({
    required this.commands,
    required this.elements,
    this.widthDots = 0,
    this.heightDots = 0,
  });
}

/// Parse IPL (Intermec) code.
IPLParseResult parseIPL(String code) {
  final commands = <IPLCommand>[];
  final elements = <LabelElement>[];
  int widthDots = 0;
  int heightDots = 0;

  // Split into STX...ETX frames
  final frames = <String>[];
  int i = 0;
  while (i < code.length) {
    if (code.codeUnitAt(i) == 0x02) {
      // STX
      i++;
      final start = i;
      while (i < code.length && code.codeUnitAt(i) != 0x03) {
        i++;
      }
      frames.add(code.substring(start, i));
      if (i < code.length) i++; // skip ETX
    } else {
      i++;
    }
  }

  for (final frame in frames) {
    // ESC commands
    if (frame.startsWith('\x1b')) {
      final cmd = frame.substring(1);
      if (cmd == 'C1') {
        commands.add(IPLCommand(type: 'CREATE_FORMAT'));
      } else if (cmd == 'P') {
        commands.add(IPLCommand(type: 'PROGRAM_MODE'));
      } else if (cmd == 'E1') {
        commands.add(IPLCommand(type: 'END_FORMAT'));
      } else if (cmd.startsWith('M')) {
        commands.add(IPLCommand(type: 'MULTIPLE', params: cmd.substring(1)));
      }
      continue;
    }

    // R command (print)
    if (frame == 'R') {
      commands.add(IPLCommand(type: 'PRINT'));
      continue;
    }

    // SI (0x0F) configuration
    if (frame.startsWith('\x0f') || frame.startsWith('<SI>')) {
      final rest =
          frame.startsWith('\x0f') ? frame.substring(1) : frame.substring(4);
      if (rest.startsWith('L')) {
        heightDots = int.tryParse(rest.substring(1)) ?? 0;
        commands.add(
          IPLCommand(type: 'LABEL_LENGTH', params: rest.substring(1)),
        );
      } else if (rest.startsWith('W')) {
        widthDots = int.tryParse(rest.substring(1)) ?? 0;
        commands.add(
          IPLCommand(type: 'LABEL_WIDTH', params: rest.substring(1)),
        );
      } else if (rest.startsWith('S')) {
        commands.add(IPLCommand(type: 'SPEED', params: rest.substring(1)));
      } else if (rest.startsWith('d')) {
        commands.add(IPLCommand(type: 'DENSITY', params: rest.substring(1)));
      }
      continue;
    }

    // Field commands (H, W, L)
    if (frame.startsWith('H') ||
        frame.startsWith('W') ||
        frame.startsWith('L')) {
      final fieldType = frame[0];
      final parts = frame.substring(1).split(';');
      final fieldData = <String, String>{};

      for (final part in parts) {
        final p = part.trim();
        if (p.isEmpty) continue;
        if (p.startsWith('o')) {
          fieldData['origin'] = p.substring(1);
        } else if (p.startsWith('f')) {
          fieldData['rotation'] = p.substring(1);
        } else if (p.startsWith('h')) {
          fieldData['height'] = p.substring(1);
        } else if (p.startsWith('w')) {
          fieldData['width'] = p.substring(1);
        } else if (p.startsWith('l')) {
          fieldData['length'] = p.substring(1);
        } else if (p.startsWith('c')) {
          fieldData['font'] = p.substring(1);
        } else if (p.startsWith('d')) {
          final dParts = p.substring(1).split(',');
          if (dParts.length > 1) {
            fieldData['data'] = dParts.sublist(1).join(',');
          }
        }
      }

      final origin = fieldData['origin']?.split(',') ?? ['0', '0'];
      final x = int.tryParse(origin[0]) ?? 0;
      final y = origin.length > 1 ? int.tryParse(origin[1]) ?? 0 : 0;
      final rot = int.tryParse(fieldData['rotation'] ?? '0') ?? 0;

      if (fieldType == 'H') {
        elements.add(
          TextElement(
            content: fieldData['data'] ?? '',
            options: TextOptions(x: x, y: y, rotation: rot * 90),
          ),
        );
        commands.add(IPLCommand(type: 'TEXT_FIELD', params: frame));
      } else if (fieldType == 'W') {
        elements.add(
          BoxElement(
            options: BoxOptions(
              x: x,
              y: y,
              width: int.tryParse(fieldData['length'] ?? '0') ?? 0,
              height: int.tryParse(fieldData['height'] ?? '0') ?? 0,
              thickness: int.tryParse(fieldData['width'] ?? '1'),
            ),
          ),
        );
        commands.add(IPLCommand(type: 'BOX_FIELD', params: frame));
      } else if (fieldType == 'L') {
        final len = int.tryParse(fieldData['length'] ?? '0') ?? 0;
        final isVertical = rot == 1;
        elements.add(
          LineElement(
            options: LineOptions(
              x1: x,
              y1: y,
              x2: isVertical ? x : x + len,
              y2: isVertical ? y + len : y,
              thickness: int.tryParse(fieldData['width'] ?? '1'),
            ),
          ),
        );
        commands.add(IPLCommand(type: 'LINE_FIELD', params: frame));
      }
    }
  }

  return IPLParseResult(
    commands: commands,
    elements: elements,
    widthDots: widthDots,
    heightDots: heightDots,
  );
}
