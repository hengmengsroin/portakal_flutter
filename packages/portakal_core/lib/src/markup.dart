import 'builder.dart';
import 'types.dart';

/// Parse HTML-like markup into a LabelBuilder.
///
/// ```dart
/// final builder = markup('''
///   <label width="40mm" height="30mm">
///     <text x="10" y="10" size="2">Hello World</text>
///     <box x="5" y="5" width="310" height="230" border="2" />
///   </label>
/// ''');
/// ```
LabelBuilder markup(String source) {
  final trimmed = source.trim();

  // Extract <label ...> attributes
  final labelMatch = RegExp(
    r'<label((?:\s+[\w-]+(?:="[^"]*")?)*)\s*>',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (labelMatch == null) {
    throw ArgumentError('Markup must contain a <label> root element');
  }

  final labelAttrs = _parseAttrs(labelMatch.group(1) ?? '');
  final unit = _getUnit(labelAttrs['width'] ?? labelAttrs['height'] ?? '');

  final config = LabelConfig(
    width: _parseUnitValue(labelAttrs['width'] ?? '40mm'),
    height: labelAttrs.containsKey('height')
        ? _parseUnitValue(labelAttrs['height']!)
        : null,
    unit: Unit.fromString(unit),
    dpi: labelAttrs.containsKey('dpi')
        ? int.tryParse(labelAttrs['dpi']!)
        : null,
    gap: labelAttrs.containsKey('gap')
        ? _parseUnitValue(labelAttrs['gap']!)
        : null,
    speed: labelAttrs.containsKey('speed')
        ? int.tryParse(labelAttrs['speed']!)
        : null,
    density: labelAttrs.containsKey('density')
        ? int.tryParse(labelAttrs['density']!)
        : null,
    copies: labelAttrs.containsKey('copies')
        ? int.tryParse(labelAttrs['copies']!)
        : null,
    printer: labelAttrs['printer'],
  );

  final b = label(config);

  // Extract inner content between <label> and </label>
  final innerMatch = RegExp(
    r'<label[^>]*>([\s\S]*)</label>',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (innerMatch == null) return b;

  final inner = innerMatch.group(1)!;

  // Find all tags
  final tagRegex = RegExp(
    r'<(\w+)((?:\s+[\w-]+(?:="[^"]*")?)*)\s*(?:/>|>([\s\S]*?)</\1>)',
    caseSensitive: false,
  );

  for (final match in tagRegex.allMatches(inner)) {
    final tagName = match.group(1)!.toLowerCase();
    final attrs = _parseAttrs(match.group(2) ?? '');
    final content = match.group(3)?.trim() ?? '';

    switch (tagName) {
      case 'text':
        b.text(
          content,
          TextOptions(
            x: attrs.containsKey('x') ? int.tryParse(attrs['x']!) : null,
            y: attrs.containsKey('y') ? int.tryParse(attrs['y']!) : null,
            font: attrs['font'],
            size: attrs.containsKey('size')
                ? int.tryParse(attrs['size']!)
                : null,
            rotation: attrs.containsKey('rotation')
                ? int.tryParse(attrs['rotation']!)
                : null,
            bold: attrs.containsKey('bold') ? true : null,
            underline: attrs.containsKey('underline') ? true : null,
            reverse: attrs.containsKey('reverse') ? true : null,
            align: attrs['align'],
            maxWidth: attrs.containsKey('maxwidth')
                ? int.tryParse(attrs['maxwidth']!)
                : attrs.containsKey('max-width')
                ? int.tryParse(attrs['max-width']!)
                : null,
          ),
        );
      case 'line':
        b.line(
          LineOptions(
            x1: int.tryParse(attrs['x1'] ?? '0') ?? 0,
            y1: int.tryParse(attrs['y1'] ?? '0') ?? 0,
            x2: int.tryParse(attrs['x2'] ?? '0') ?? 0,
            y2: int.tryParse(attrs['y2'] ?? '0') ?? 0,
            thickness: attrs.containsKey('thickness')
                ? int.tryParse(attrs['thickness']!)
                : attrs.containsKey('border')
                ? int.tryParse(attrs['border']!)
                : null,
          ),
        );
      case 'box':
        b.box(
          BoxOptions(
            x: int.tryParse(attrs['x'] ?? '0') ?? 0,
            y: int.tryParse(attrs['y'] ?? '0') ?? 0,
            width: int.tryParse(attrs['width'] ?? '100') ?? 100,
            height: int.tryParse(attrs['height'] ?? '100') ?? 100,
            thickness: attrs.containsKey('thickness')
                ? int.tryParse(attrs['thickness']!)
                : attrs.containsKey('border')
                ? int.tryParse(attrs['border']!)
                : null,
            radius: attrs.containsKey('radius')
                ? int.tryParse(attrs['radius']!)
                : null,
          ),
        );
      case 'circle':
        b.circle(
          CircleOptions(
            x: int.tryParse(attrs['x'] ?? '0') ?? 0,
            y: int.tryParse(attrs['y'] ?? '0') ?? 0,
            diameter:
                int.tryParse(attrs['diameter'] ?? attrs['size'] ?? '50') ?? 50,
            thickness: attrs.containsKey('thickness')
                ? int.tryParse(attrs['thickness']!)
                : null,
          ),
        );
      case 'ellipse':
        b.ellipse(
          EllipseOptions(
            x: int.tryParse(attrs['x'] ?? '0') ?? 0,
            y: int.tryParse(attrs['y'] ?? '0') ?? 0,
            width: int.tryParse(attrs['width'] ?? '100') ?? 100,
            height: int.tryParse(attrs['height'] ?? '60') ?? 60,
            thickness: attrs.containsKey('thickness')
                ? int.tryParse(attrs['thickness']!)
                : null,
          ),
        );
      case 'reverse':
        b.reverse(
          ReverseOptions(
            x: int.tryParse(attrs['x'] ?? '0') ?? 0,
            y: int.tryParse(attrs['y'] ?? '0') ?? 0,
            width: int.tryParse(attrs['width'] ?? '100') ?? 100,
            height: int.tryParse(attrs['height'] ?? '30') ?? 30,
          ),
        );
      case 'erase':
        b.erase(
          EraseOptions(
            x: int.tryParse(attrs['x'] ?? '0') ?? 0,
            y: int.tryParse(attrs['y'] ?? '0') ?? 0,
            width: int.tryParse(attrs['width'] ?? '100') ?? 100,
            height: int.tryParse(attrs['height'] ?? '30') ?? 30,
          ),
        );
      case 'raw':
        b.raw(content);
    }
  }

  return b;
}

/// Parse attributes string.
Map<String, String> _parseAttrs(String s) {
  final attrs = <String, String>{};
  final re = RegExp(r'([\w-]+)(?:="([^"]*)")?');
  for (final m in re.allMatches(s)) {
    attrs[m.group(1)!] = m.group(2) ?? 'true';
  }
  return attrs;
}

/// Parse unit value (strip units, return number).
double _parseUnitValue(String s) {
  return double.tryParse(
        s.replaceAll(RegExp(r'\s*(mm|inch|dot|px)$', caseSensitive: false), ''),
      ) ??
      0;
}

/// Get unit from attribute string.
String _getUnit(String s) {
  if (s.endsWith('mm')) return 'mm';
  if (s.endsWith('inch') || s.endsWith('in')) return 'inch';
  return 'dot';
}
