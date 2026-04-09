import '../types.dart';

/// Result of parsing TSC/TSPL code.
class TSPLParseResult {
  final List<TSPLCommand> commands;
  final List<LabelElement> elements;
  final int widthDots;
  final int heightDots;
  final int dpi;
  final List<String> warnings;

  TSPLParseResult({
    required this.commands,
    required this.elements,
    this.widthDots = 0,
    this.heightDots = 0,
    this.dpi = 203,
    this.warnings = const [],
  });
}

/// A parsed TSPL command.
class TSPLCommand {
  final String cmd;
  final Map<String, dynamic> _data;

  TSPLCommand(this.cmd, [Map<String, dynamic>? data]) : _data = data ?? {};

  dynamic operator [](String key) => _data[key];
  void operator []=(String key, dynamic value) => _data[key] = value;

  // Convenience getters used in tests via toMatchObject pattern
  double? get widthMM => _data['widthMM'] as double?;
  double? get heightMM => _data['heightMM'] as double?;
  String? get unit => _data['unit'] as String?;
  double? get distanceMM => _data['distanceMM'] as double?;
  double? get offsetMM => _data['offsetMM'] as double?;
  int? get x => _data['x'] as int?;
  int? get y => _data['y'] as int?;
  String? get font => _data['font'] as String?;
  int? get rotation => _data['rotation'] as int?;
  int? get xMul => _data['xMul'] as int?;
  int? get yMul => _data['yMul'] as int?;
  String? get content => _data['content'] as String?;
  int? get thickness => _data['thickness'] as int?;
  int? get xEnd => _data['xEnd'] as int?;
  int? get yEnd => _data['yEnd'] as int?;
  int? get diameter => _data['diameter'] as int?;
  int? get width => (_data['width'] as num?)?.toInt();
  int? get height => (_data['height'] as num?)?.toInt();
  int? get x1 => _data['x1'] as int?;
  int? get y1 => _data['y1'] as int?;
  int? get x2 => _data['x2'] as int?;
  int? get y2 => _data['y2'] as int?;
  String? get type_str => _data['type'] as String?;
  int? get readable => _data['readable'] as int?;
  int? get narrow => _data['narrow'] as int?;
  int? get wide => _data['wide'] as int?;
  String? get ecc => _data['ecc'] as String?;
  int? get cellWidth => _data['cellWidth'] as int?;
  String? get mode => _data['mode'] as String?;
  String? get model => _data['model'] as String?;
  String? get mask => _data['mask'] as String?;
  int? get alignment => _data['alignment'] as int?;
  int? get sets => _data['sets'] as int?;
  int? get copies => _data['copies'] as int?;
  dynamic get value => _data['value'];
  int? get widthBytes => _data['widthBytes'] as int?;
  int? get mode_int => _data['mode'] is int ? _data['mode'] as int : null;
  int? get radius => _data['radius'] as int?;
  String? get key => _data['key'] as String?;
  String? get filename => _data['filename'] as String?;
  String? get raw => _data['raw'] as String?;
  String? get variable => _data['variable'] as String?;
  String? get start => _data['start'] as String?;
  String? get end_val => _data['end'] as String?;
  String? get step => _data['step'] as String?;
  String? get condition => _data['condition'] as String?;
  String? get label_name => _data['label'] as String?;
  String? get comment => _data['comment'] as String?;
  String? get name => _data['name'] as String?;
  String? get subcommand => _data['subcommand'] as String?;
  String? get codepage => _data['codepage'] as String?;
  String? get code_str => _data['code'] as String?;
  int? get dots => _data['dots'] as int?;
  int? get level => _data['level'] as int?;
  int? get interval => _data['interval'] as int?;
  int? get maxLen => _data['maxLen'] as int?;
  int? get ms => _data['ms'] as int?;
  String? get page => _data['page'] as String?;
  int? get direction => _data['direction'] as int?;
  int? get mirror => _data['mirror'] as int?;
  double? get distance => _data['distance'] as double?;
  int? get paperLen => _data['paperLen'] as int?;
  int? get gapLen => _data['gapLen'] as int?;
  int? get bpp => _data['bpp'] as int?;
  int? get contrast => _data['contrast'] as int?;
  String? get sym => _data['sym'] as String?;
  int? get pixMult => _data['pixMult'] as int?;

  Map<String, dynamic> toMap() => {'cmd': cmd, ..._data};
}

/// Parse a TSPL code string into structured commands and elements.
///
///This is the full parser with support for all TSPL commands.
TSPLParseResult parseTSPL(String code) {
  if (code.trim().isEmpty) {
    return TSPLParseResult(commands: [], elements: []);
  }

  final lines = code.split(RegExp(r'\r?\n'));
  final commands = <TSPLCommand>[];
  final elements = <LabelElement>[];
  int widthDots = 0;
  int heightDots = 0;
  int dpi = 203;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;

    final cmd = _parseTSPLLine(line, lines, i);
    if (cmd != null) {
      commands.add(cmd);

      // Extract label dimensions
      if (cmd.cmd == 'SIZE') {
        final u = cmd.unit ?? 'mm';
        final w = cmd.widthMM ?? 0;
        final h = cmd.heightMM ?? 0;
        if (u == 'mm') {
          widthDots = (w / 25.4 * dpi).round();
          heightDots = (h / 25.4 * dpi).round();
        } else if (u == 'inch') {
          widthDots = (w * dpi).round();
          heightDots = (h * dpi).round();
        } else if (u == 'dot') {
          widthDots = w.round();
          heightDots = h.round();
        }
      }

      // Build elements for preview
      final el = _commandToElement(cmd);
      if (el != null) elements.add(el);
    }
  }

  return TSPLParseResult(
    commands: commands,
    elements: elements,
    widthDots: widthDots,
    heightDots: heightDots,
    dpi: dpi,
  );
}

/// Simplified parser for web — returns widthDots, heightDots, elements.
TSPLParseResult parseTSC(String code) => parseTSPL(code);

TSPLCommand? _parseTSPLLine(String line, List<String> lines, int lineIdx) {
  // Labels (ending with :)
  if (line.endsWith(':') && !line.contains(' ') && !line.contains(',')) {
    return TSPLCommand('LABEL', {'name': line.substring(0, line.length - 1)});
  }

  // Assignments
  if (RegExp(r'^[A-Z\$@]\S*\s*=\s*').hasMatch(line)) {
    final eqIdx = line.indexOf('=');
    final variable = line.substring(0, eqIdx).trim();
    final value = line.substring(eqIdx + 1).trim();
    return TSPLCommand('ASSIGNMENT', {'variable': variable, 'value': value});
  }

  final parts = line.split(RegExp(r'\s+'));
  final cmdName = parts[0].toUpperCase();
  final rest = line.substring(parts[0].length).trim();

  switch (cmdName) {
    case 'SIZE':
      return _parseSize(rest);
    case 'GAP':
      return _parseGap(rest);
    case 'GAPDETECT':
      if (rest.isEmpty) return TSPLCommand('GAPDETECT');
      final p = rest.split(',').map((s) => s.trim()).toList();
      return TSPLCommand('GAPDETECT', {
        'paperLen': int.tryParse(p[0]) ?? 0,
        'gapLen': p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0,
      });
    case 'BLINEDETECT':
      return TSPLCommand('BLINEDETECT');
    case 'AUTODETECT':
      final p = rest.split(',').map((s) => s.trim()).toList();
      return TSPLCommand('AUTODETECT', {
        'paperLen': int.tryParse(p[0]) ?? 0,
        'gapLen': p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0,
      });
    case 'BLINE':
      return _parseBline(rest);
    case 'OFFSET':
      return _parseOffset(rest);
    case 'SPEED':
      return TSPLCommand('SPEED', {'value': double.tryParse(rest) ?? 0});
    case 'DENSITY':
      return TSPLCommand('DENSITY', {'value': int.tryParse(rest) ?? 0});
    case 'DIRECTION':
      final p = rest.split(',').map((s) => s.trim()).toList();
      final data = <String, dynamic>{'direction': int.tryParse(p[0]) ?? 0};
      if (p.length > 1) data['mirror'] = int.tryParse(p[1]) ?? 0;
      return TSPLCommand('DIRECTION', data);
    case 'REFERENCE':
      final p = rest.split(',').map((s) => s.trim()).toList();
      return TSPLCommand('REFERENCE', {
        'x': int.tryParse(p[0]) ?? 0,
        'y': p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0,
      });
    case 'SHIFT':
      final p = rest.split(',').map((s) => s.trim()).toList();
      final data = <String, dynamic>{'y': int.tryParse(p[0]) ?? 0};
      if (p.length > 1) data['x'] = int.tryParse(p[0]) ?? 0;
      if (p.length > 1) data['y'] = int.tryParse(p[1]) ?? 0;
      return TSPLCommand('SHIFT', data);
    case 'COUNTRY':
      return TSPLCommand('COUNTRY', {'code': rest});
    case 'CODEPAGE':
      return TSPLCommand('CODEPAGE', {'codepage': rest});
    case 'CLS':
      return TSPLCommand('CLS');
    case 'FEED':
      return TSPLCommand('FEED', {'dots': int.tryParse(rest) ?? 0});
    case 'BACKFEED':
      return TSPLCommand('BACKFEED', {'dots': int.tryParse(rest) ?? 0});
    case 'BACKUP':
      return TSPLCommand('BACKUP', {'dots': int.tryParse(rest) ?? 0});
    case 'FORMFEED':
      return TSPLCommand('FORMFEED');
    case 'HOME':
      return TSPLCommand('HOME');
    case 'PRINT':
      final p = rest.split(',').map((s) => s.trim()).toList();
      final data = <String, dynamic>{'sets': int.tryParse(p[0]) ?? 1};
      if (p.length > 1) data['copies'] = int.tryParse(p[1]) ?? 1;
      return TSPLCommand('PRINT', data);
    case 'SOUND':
      final p = rest.split(',').map((s) => s.trim()).toList();
      return TSPLCommand('SOUND', {
        'level': int.tryParse(p[0]) ?? 0,
        'interval': p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0,
      });
    case 'CUT':
      return TSPLCommand('CUT');
    case 'LIMITFEED':
      return TSPLCommand('LIMITFEED', {'maxLen': int.tryParse(rest) ?? 0});
    case 'SELFTEST':
      if (rest.isEmpty) return TSPLCommand('SELFTEST');
      return TSPLCommand('SELFTEST', {'page': rest});
    case 'EOJ':
      return TSPLCommand('EOJ');
    case 'EOP':
      return TSPLCommand('EOP');
    case 'DELAY':
      return TSPLCommand('DELAY', {'ms': int.tryParse(rest) ?? 0});
    case 'INITIALPRINTER':
      return TSPLCommand('INITIALPRINTER');
    case 'TEXT':
      return _parseText(rest);
    case 'BLOCK':
      return _parseBlock(rest);
    case 'BARCODE':
      return _parseBarcode(rest);
    case 'BAR':
      return _parseBar(rest);
    case 'BOX':
      return _parseBox(rest);
    case 'CIRCLE':
      return _parseCircle(rest);
    case 'ELLIPSE':
      return _parseEllipse(rest);
    case 'DIAGONAL':
      return _parseDiagonal(rest);
    case 'REVERSE':
      return _parseReverse(rest);
    case 'ERASE':
      return _parseErase(rest);
    case 'BITMAP':
      return _parseBitmap(rest);
    case 'QRCODE':
      return _parseQRCode(rest);
    case 'DMATRIX':
      return _parseDMatrix(rest);
    case 'PDF417':
      return _parsePDF417(rest);
    case 'AZTEC':
      return _parseAztec(rest);
    case 'MAXICODE':
      return _parseMaxicode(rest);
    case 'MPDF417':
      return _parseMPDF417(rest);
    case 'RSS':
      return _parseRSS(rest);
    case 'CODABLOCK':
      return _parseCodablock(rest);
    case 'TLC39':
      return _parseTLC39(rest);
    case 'PUTBMP':
      return _parsePutBMP(rest);
    case 'PUTPCX':
      return _parsePutPCX(rest);
    case 'SET':
      final setParts = rest.split(RegExp(r'\s+'));
      final setKey = setParts[0];
      final setValue = setParts.length > 1 ? setParts.sublist(1).join(' ') : '';
      return TSPLCommand('SET', {'key': setKey, 'value': setValue});
    case 'DOWNLOAD':
      return TSPLCommand('DOWNLOAD', {'filename': _extractQuoted(rest)});
    case 'FILES':
      return TSPLCommand('FILES');
    case 'KILL':
      return TSPLCommand('KILL', {'filename': _extractQuoted(rest)});
    case 'MOVE':
      return TSPLCommand('MOVE');
    case 'RUN':
      return TSPLCommand('RUN', {'filename': _extractQuoted(rest)});
    case 'FOR':
      return _parseFor(rest);
    case 'NEXT':
      return TSPLCommand('NEXT');
    case 'IF':
      final cond = rest.replaceAll(RegExp(r'\s+THEN$', caseSensitive: false), '');
      return TSPLCommand('IF', {'condition': cond});
    case 'ENDIF':
      return TSPLCommand('ENDIF');
    case 'WHILE':
      return TSPLCommand('WHILE', {'condition': rest});
    case 'WEND':
      return TSPLCommand('WEND');
    case 'GOTO':
      return TSPLCommand('GOTO', {'label': rest});
    case 'GOSUB':
      return TSPLCommand('GOSUB', {'label': rest});
    case 'REM':
      return TSPLCommand('REM', {'comment': rest});
    case 'RETURN':
      return TSPLCommand('RETURN');
    case 'END':
      return TSPLCommand('END');
    case 'BEEP':
      return TSPLCommand('BEEP');
    case 'OPEN':
      return TSPLCommand('OPEN', {'params': rest});
    case 'CLOSE':
      return TSPLCommand('CLOSE', {'params': rest});
    case 'WRITE':
      return TSPLCommand('WRITE', {'params': rest});
    case 'READ':
      return TSPLCommand('READ', {'params': rest});
    case 'SEEK':
      return TSPLCommand('SEEK', {'params': rest});
    case 'COPY':
      return TSPLCommand('COPY', {'params': rest});
    case 'NET':
      final netParts = rest.split(RegExp(r'\s+'));
      return TSPLCommand('NET', {'subcommand': netParts[0], 'params': rest});
    case 'WLAN':
      final wlanParts = rest.split(RegExp(r'\s+'));
      return TSPLCommand('WLAN', {'subcommand': wlanParts[0], 'params': rest});
    case 'NFC':
      final nfcParts = rest.split(RegExp(r'\s+'));
      return TSPLCommand('NFC', {'subcommand': nfcParts[0], 'params': rest});
    default:
      // Check for function-style commands
      if (line.startsWith('GETSENSOR')) {
        return TSPLCommand('GETSENSOR', {'params': rest});
      }
      if (line.startsWith('GETSETTING')) {
        return TSPLCommand('GETSETTING', {'params': rest});
      }
      return TSPLCommand('UNKNOWN', {'raw': line});
  }
}

TSPLCommand _parseSize(String rest) {
  // SIZE 40 mm,30 mm | SIZE 4,3 | SIZE 320 dot,240 dot
  final cleaned = rest.replaceAll(' mm', ' mm').replaceAll(' dot', ' dot');
  String unit = 'inch';
  if (cleaned.contains('mm')) {
    unit = 'mm';
  } else if (cleaned.contains('dot')) {
    unit = 'dot';
  }

  final parts = cleaned.split(',').map((s) => s.trim()).toList();
  final w = double.tryParse(parts[0].replaceAll(RegExp(r'\s*(mm|dot)'), '')) ?? 0;
  final h = parts.length > 1
      ? double.tryParse(parts[1].replaceAll(RegExp(r'\s*(mm|dot)'), '')) ?? 0
      : 0;

  return TSPLCommand('SIZE', {'widthMM': w, 'heightMM': h, 'unit': unit});
}

TSPLCommand _parseGap(String rest) {
  final parts = rest.split(',').map((s) => s.trim()).toList();
  final dist = double.tryParse(parts[0].replaceAll(RegExp(r'\s*mm'), '')) ?? 0;
  final off = parts.length > 1
      ? double.tryParse(parts[1].replaceAll(RegExp(r'\s*mm'), '')) ?? 0
      : 0;
  return TSPLCommand('GAP', {'distanceMM': dist, 'offsetMM': off});
}

TSPLCommand _parseBline(String rest) {
  final parts = rest.split(',').map((s) => s.trim()).toList();
  final h = double.tryParse(parts[0].replaceAll(RegExp(r'\s*mm'), '')) ?? 0;
  final off = parts.length > 1
      ? double.tryParse(parts[1].replaceAll(RegExp(r'\s*mm'), '')) ?? 0
      : 0;
  return TSPLCommand('BLINE', {'height': h, 'offset': off});
}

TSPLCommand _parseOffset(String rest) {
  String unit = 'mm';
  if (rest.contains('dot')) {
    unit = 'dot';
  }
  final val = double.tryParse(rest.replaceAll(RegExp(r'\s*(mm|dot)'), '')) ?? 0;
  return TSPLCommand('OFFSET', {'distance': val, 'unit': unit});
}

TSPLCommand _parseText(String rest) {
  // TEXT x,y,"font",rotation,xMul,yMul[,alignment],"content"
  final params = _splitParams(rest);
  if (params.length < 7) return TSPLCommand('TEXT', {'raw': rest});

  final data = <String, dynamic>{
    'x': int.tryParse(params[0]) ?? 0,
    'y': int.tryParse(params[1]) ?? 0,
    'font': _unquote(params[2]),
    'rotation': int.tryParse(params[3]) ?? 0,
    'xMul': int.tryParse(params[4]) ?? 1,
    'yMul': int.tryParse(params[5]) ?? 1,
  };

  // Check if there's an alignment parameter
  if (params.length >= 8) {
    final maybeAlign = int.tryParse(params[6]);
    if (maybeAlign != null) {
      data['alignment'] = maybeAlign;
      data['content'] = _unquote(params[7]);
    } else {
      data['content'] = _unquote(params[6]);
    }
  } else {
    data['content'] = _unquote(params[6]);
  }

  return TSPLCommand('TEXT', data);
}

TSPLCommand _parseBlock(String rest) {
  final params = _splitParams(rest);
  if (params.length < 11) return TSPLCommand('BLOCK', {'raw': rest});
  return TSPLCommand('BLOCK', {
    'x': int.tryParse(params[0]) ?? 0,
    'y': int.tryParse(params[1]) ?? 0,
    'width': int.tryParse(params[2]) ?? 0,
    'height': int.tryParse(params[3]) ?? 0,
    'font': _unquote(params[4]),
    'rotation': int.tryParse(params[5]) ?? 0,
    'xMul': int.tryParse(params[6]) ?? 1,
    'yMul': int.tryParse(params[7]) ?? 1,
    'space': int.tryParse(params[8]) ?? 0,
    'alignment': int.tryParse(params[9]) ?? 0,
    'content': _unquote(params[10]),
  });
}

TSPLCommand _parseBarcode(String rest) {
  final params = _splitParams(rest);
  if (params.length < 9) return TSPLCommand('BARCODE', {'raw': rest});

  final data = <String, dynamic>{
    'x': int.tryParse(params[0]) ?? 0,
    'y': int.tryParse(params[1]) ?? 0,
    'type': _unquote(params[2]),
    'height': int.tryParse(params[3]) ?? 0,
    'readable': int.tryParse(params[4]) ?? 0,
    'rotation': int.tryParse(params[5]) ?? 0,
    'narrow': int.tryParse(params[6]) ?? 0,
    'wide': int.tryParse(params[7]) ?? 0,
  };

  if (params.length >= 10) {
    final maybeAlign = int.tryParse(params[8]);
    if (maybeAlign != null) {
      data['alignment'] = maybeAlign;
      data['content'] = _unquote(params[9]);
    } else {
      data['content'] = _unquote(params[8]);
    }
  } else {
    data['content'] = _unquote(params[8]);
  }

  return TSPLCommand('BARCODE', data);
}

TSPLCommand _parseBar(String rest) {
  final p = rest.split(',').map((s) => s.trim()).toList();
  return TSPLCommand('BAR', {
    'x': int.tryParse(p[0]) ?? 0,
    'y': int.tryParse(p[1]) ?? 0,
    'width': int.tryParse(p[2]) ?? 0,
    'height': int.tryParse(p[3]) ?? 0,
  });
}

TSPLCommand _parseBox(String rest) {
  final p = rest.split(',').map((s) => s.trim()).toList();
  final data = <String, dynamic>{
    'x': int.tryParse(p[0]) ?? 0,
    'y': int.tryParse(p[1]) ?? 0,
    'xEnd': int.tryParse(p[2]) ?? 0,
    'yEnd': int.tryParse(p[3]) ?? 0,
    'thickness': int.tryParse(p[4]) ?? 1,
  };
  if (p.length > 5) data['radius'] = int.tryParse(p[5]) ?? 0;
  return TSPLCommand('BOX', data);
}

TSPLCommand _parseCircle(String rest) {
  final p = rest.split(',').map((s) => s.trim()).toList();
  return TSPLCommand('CIRCLE', {
    'x': int.tryParse(p[0]) ?? 0,
    'y': int.tryParse(p[1]) ?? 0,
    'diameter': int.tryParse(p[2]) ?? 0,
    'thickness': int.tryParse(p[3]) ?? 1,
  });
}

TSPLCommand _parseEllipse(String rest) {
  final p = rest.split(',').map((s) => s.trim()).toList();
  return TSPLCommand('ELLIPSE', {
    'x': int.tryParse(p[0]) ?? 0,
    'y': int.tryParse(p[1]) ?? 0,
    'width': int.tryParse(p[2]) ?? 0,
    'height': int.tryParse(p[3]) ?? 0,
    'thickness': p.length > 4 ? int.tryParse(p[4]) ?? 1 : 1,
  });
}

TSPLCommand _parseDiagonal(String rest) {
  final p = rest.split(',').map((s) => s.trim()).toList();
  return TSPLCommand('DIAGONAL', {
    'x1': int.tryParse(p[0]) ?? 0,
    'y1': int.tryParse(p[1]) ?? 0,
    'x2': int.tryParse(p[2]) ?? 0,
    'y2': int.tryParse(p[3]) ?? 0,
    'thickness': int.tryParse(p[4]) ?? 1,
  });
}

TSPLCommand _parseReverse(String rest) {
  final p = rest.split(',').map((s) => s.trim()).toList();
  return TSPLCommand('REVERSE', {
    'x': int.tryParse(p[0]) ?? 0,
    'y': int.tryParse(p[1]) ?? 0,
    'width': int.tryParse(p[2]) ?? 0,
    'height': int.tryParse(p[3]) ?? 0,
  });
}

TSPLCommand _parseErase(String rest) {
  final p = rest.split(',').map((s) => s.trim()).toList();
  return TSPLCommand('ERASE', {
    'x': int.tryParse(p[0]) ?? 0,
    'y': int.tryParse(p[1]) ?? 0,
    'width': int.tryParse(p[2]) ?? 0,
    'height': int.tryParse(p[3]) ?? 0,
  });
}

TSPLCommand _parseBitmap(String rest) {
  final p = rest.split(',').map((s) => s.trim()).toList();
  return TSPLCommand('BITMAP', {
    'x': int.tryParse(p[0]) ?? 0,
    'y': int.tryParse(p[1]) ?? 0,
    'widthBytes': int.tryParse(p[2]) ?? 0,
    'height': int.tryParse(p[3]) ?? 0,
    'mode': int.tryParse(p[4]) ?? 0,
  });
}

TSPLCommand _parseQRCode(String rest) {
  final params = _splitParams(rest);
  if (params.length < 7) return TSPLCommand('QRCODE', {'raw': rest});

  final data = <String, dynamic>{
    'x': int.tryParse(params[0]) ?? 0,
    'y': int.tryParse(params[1]) ?? 0,
    'ecc': params[2],
    'cellWidth': int.tryParse(params[3]) ?? 0,
    'mode': params[4],
    'rotation': int.tryParse(params[5]) ?? 0,
  };

  // Find content — last quoted param
  int contentIdx = params.length - 1;
  data['content'] = _unquote(params[contentIdx]);

  // Parse optional model and mask
  for (int j = 6; j < contentIdx; j++) {
    if (params[j].startsWith('M')) data['model'] = params[j];
    if (params[j].startsWith('S')) data['mask'] = params[j];
  }

  return TSPLCommand('QRCODE', data);
}

TSPLCommand _parseDMatrix(String rest) {
  final params = _splitParams(rest);
  return TSPLCommand('DMATRIX', {
    'x': int.tryParse(params[0]) ?? 0,
    'y': int.tryParse(params[1]) ?? 0,
    'width': int.tryParse(params[2]) ?? 0,
    'height': int.tryParse(params[3]) ?? 0,
    'content': _unquote(params.last),
  });
}

TSPLCommand _parsePDF417(String rest) {
  final params = _splitParams(rest);
  return TSPLCommand('PDF417', {
    'x': int.tryParse(params[0]) ?? 0,
    'y': int.tryParse(params[1]) ?? 0,
    'width': int.tryParse(params[2]) ?? 0,
    'height': int.tryParse(params[3]) ?? 0,
    'rotation': int.tryParse(params[4]) ?? 0,
    'content': _unquote(params.last),
  });
}

TSPLCommand _parseAztec(String rest) {
  final params = _splitParams(rest);
  return TSPLCommand('AZTEC', {
    'x': int.tryParse(params[0]) ?? 0,
    'y': int.tryParse(params[1]) ?? 0,
    'rotation': int.tryParse(params[2]) ?? 0,
    'content': _unquote(params.last),
  });
}

TSPLCommand _parseMaxicode(String rest) {
  final params = _splitParams(rest);
  return TSPLCommand('MAXICODE', {
    'x': int.tryParse(params[0]) ?? 0,
    'y': int.tryParse(params[1]) ?? 0,
    'mode': int.tryParse(params[2]) ?? 0,
    'content': _unquote(params.last),
  });
}

TSPLCommand _parseMPDF417(String rest) {
  final params = _splitParams(rest);
  return TSPLCommand('MPDF417', {
    'x': int.tryParse(params[0]) ?? 0,
    'y': int.tryParse(params[1]) ?? 0,
    'rotation': int.tryParse(params[2]) ?? 0,
    'content': _unquote(params.last),
  });
}

TSPLCommand _parseRSS(String rest) {
  final params = _splitParams(rest);
  return TSPLCommand('RSS', {
    'x': int.tryParse(params[0]) ?? 0,
    'y': int.tryParse(params[1]) ?? 0,
    'sym': _unquote(params[2]),
    'rotation': int.tryParse(params[3]) ?? 0,
    'pixMult': int.tryParse(params[4]) ?? 0,
    'sepHt': int.tryParse(params[5]) ?? 0,
    'content': _unquote(params.last),
  });
}

TSPLCommand _parseCodablock(String rest) {
  final params = _splitParams(rest);
  return TSPLCommand('CODABLOCK', {
    'x': int.tryParse(params[0]) ?? 0,
    'y': int.tryParse(params[1]) ?? 0,
    'rotation': int.tryParse(params[2]) ?? 0,
    'content': _unquote(params.last),
  });
}

TSPLCommand _parseTLC39(String rest) {
  final params = _splitParams(rest);
  return TSPLCommand('TLC39', {
    'x': int.tryParse(params[0]) ?? 0,
    'y': int.tryParse(params[1]) ?? 0,
    'rotation': int.tryParse(params[2]) ?? 0,
    'content': _unquote(params.last),
  });
}

TSPLCommand _parsePutBMP(String rest) {
  final params = _splitParams(rest);
  final data = <String, dynamic>{
    'x': int.tryParse(params[0]) ?? 0,
    'y': int.tryParse(params[1]) ?? 0,
    'filename': _unquote(params[2]),
  };
  if (params.length > 3) data['bpp'] = int.tryParse(params[3]);
  if (params.length > 4) data['contrast'] = int.tryParse(params[4]);
  return TSPLCommand('PUTBMP', data);
}

TSPLCommand _parsePutPCX(String rest) {
  final params = _splitParams(rest);
  return TSPLCommand('PUTPCX', {
    'x': int.tryParse(params[0]) ?? 0,
    'y': int.tryParse(params[1]) ?? 0,
    'filename': _unquote(params[2]),
  });
}

TSPLCommand _parseFor(String rest) {
  // FOR I = 1 TO 10 STEP 2
  final m = RegExp(r'(\w+)\s*=\s*(\S+)\s+TO\s+(\S+)(?:\s+STEP\s+(\S+))?', caseSensitive: false)
      .firstMatch(rest);
  if (m == null) return TSPLCommand('FOR', {'raw': rest});
  return TSPLCommand('FOR', {
    'variable': m.group(1)!,
    'start': m.group(2)!,
    'end': m.group(3)!,
    'step': m.group(4) ?? '1',
  });
}

/// Convert a command to a LabelElement for preview.
LabelElement? _commandToElement(TSPLCommand cmd) {
  switch (cmd.cmd) {
    case 'TEXT':
      if (cmd.content == null) return null;
      return TextElement(
        content: cmd.content!,
        options: TextOptions(
          x: cmd.x,
          y: cmd.y,
          font: cmd.font,
          size: cmd.xMul,
          rotation: cmd.rotation,
        ),
      );
    case 'BOX':
      return BoxElement(
        options: BoxOptions(
          x: cmd.x ?? 0,
          y: cmd.y ?? 0,
          width: (cmd.xEnd ?? 0) - (cmd.x ?? 0),
          height: (cmd.yEnd ?? 0) - (cmd.y ?? 0),
          thickness: cmd.thickness,
        ),
      );
    case 'BAR':
      return LineElement(
        options: LineOptions(
          x1: cmd.x ?? 0,
          y1: cmd.y ?? 0,
          x2: (cmd.x ?? 0) + (cmd.width ?? 0),
          y2: cmd.y ?? 0,
          thickness: cmd.height,
        ),
      );
    case 'CIRCLE':
      return CircleElement(
        options: CircleOptions(
          x: cmd.x ?? 0,
          y: cmd.y ?? 0,
          diameter: cmd.diameter ?? 0,
          thickness: cmd.thickness,
        ),
      );
    case 'ELLIPSE':
      return EllipseElement(
        options: EllipseOptions(
          x: cmd.x ?? 0,
          y: cmd.y ?? 0,
          width: cmd.width ?? 0,
          height: cmd.height ?? 0,
          thickness: cmd.thickness,
        ),
      );
    case 'DIAGONAL':
      return LineElement(
        options: LineOptions(
          x1: cmd.x1 ?? 0,
          y1: cmd.y1 ?? 0,
          x2: cmd.x2 ?? 0,
          y2: cmd.y2 ?? 0,
          thickness: cmd.thickness,
        ),
      );
    case 'REVERSE':
      return ReverseElement(
        options: ReverseOptions(
          x: cmd.x ?? 0,
          y: cmd.y ?? 0,
          width: cmd.width ?? 0,
          height: cmd.height ?? 0,
        ),
      );
    case 'ERASE':
      return EraseElement(
        options: EraseOptions(
          x: cmd.x ?? 0,
          y: cmd.y ?? 0,
          width: cmd.width ?? 0,
          height: cmd.height ?? 0,
        ),
      );
    default:
      return null;
  }
}

/// Split TSPL parameters, respecting quoted strings.
List<String> _splitParams(String input) {
  final result = <String>[];
  final buf = StringBuffer();
  bool inQuotes = false;

  for (int i = 0; i < input.length; i++) {
    final ch = input[i];
    if (ch == '"') {
      inQuotes = !inQuotes;
      buf.write(ch);
    } else if (ch == ',' && !inQuotes) {
      result.add(buf.toString().trim());
      buf.clear();
    } else {
      buf.write(ch);
    }
  }
  if (buf.isNotEmpty) result.add(buf.toString().trim());
  return result;
}

/// Remove surrounding quotes.
String _unquote(String s) {
  s = s.trim();
  if (s.startsWith('"') && s.endsWith('"')) {
    return s.substring(1, s.length - 1);
  }
  return s;
}

/// Extract quoted filename.
String _extractQuoted(String s) {
  final m = RegExp(r'"([^"]*)"').firstMatch(s);
  return m?.group(1) ?? s.trim();
}
