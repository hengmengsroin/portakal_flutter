import 'dart:math';
import 'types.dart';

/// Escape XML special characters.
String _escapeXml(String s) {
  return s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}

/// Calculate font pixel height from size and yScale.
int _calcFontSize(int? size, int? yScale) {
  if (yScale != null && yScale > 10) return yScale;
  return max(8, (size ?? 1) * 12);
}

/// Baseline offset ratio.
double _baselineRatio(String? font) {
  return font == '0' ? 0.78 : 0.82;
}

/// CSS font-family.
String _fontFamily(String? font) {
  if (font == '0') return "'Helvetica Neue', Helvetica, Arial, sans-serif";
  return 'monospace';
}

String _renderElement(LabelElement el) {
  switch (el) {
    case TextElement():
      final o = el.options;
      final x = o.x ?? 0;
      final y = o.y ?? 0;
      final fs = _calcFontSize(o.size, o.yScale);
      final bl = _baselineRatio(o.font);
      final ff = _fontFamily(o.font);
      final weight = (o.bold == true) ? 'bold' : 'normal';
      final decoration = (o.underline == true) ? ' text-decoration="underline"' : '';
      final transform = (o.rotation != null && o.rotation != 0) ? ' transform="rotate(${o.rotation} $x $y)"' : '';

      var anchor = '';
      var textX = x;
      if (o.maxWidth != null && o.align == 'center') {
        anchor = ' text-anchor="middle"';
        textX = x + o.maxWidth! ~/ 2;
      } else if (o.maxWidth != null && o.align == 'right') {
        anchor = ' text-anchor="end"';
        textX = x + o.maxWidth!;
      }

      final fill = (o.reverse == true) ? '#fff' : '#000';
      final svgY = ((y + fs * bl) * 100).round() / 100;
      return '<text x="$textX" y="$svgY" fill="$fill" font-size="$fs" font-weight="$weight" font-family="$ff"$anchor$decoration$transform>${_escapeXml(el.content)}</text>';

    case ImageElement():
      final o = el.options;
      final x = o.x ?? 0;
      final y = o.y ?? 0;
      final bmp = el.bitmap;
      final w = o.width ?? bmp.width;
      final h = o.height ?? bmp.height;
      final step = max(1, max(bmp.width, bmp.height) ~/ 100);
      final scaleX = w / bmp.width;
      final scaleY = h / bmp.height;
      final buf = StringBuffer();

      for (var py = 0; py < bmp.height; py += step) {
        for (var px = 0; px < bmp.width; px += step) {
          final byteIdx = py * bmp.bytesPerRow + (px ~/ 8);
          final bitIdx = 7 - (px % 8);
          final isBlack = (bmp.data[byteIdx] >> bitIdx) & 1;
          if (isBlack == 1) {
            buf.write('<rect x="${x + px * scaleX}" y="${y + py * scaleY}" width="${step * scaleX}" height="${step * scaleY}" fill="#000"/>');
          }
        }
      }
      return buf.toString();

    case BoxElement():
      final o = el.options;
      final t = o.thickness ?? 1;
      final rx = o.radius ?? 0;

      if (t >= min(o.width, o.height)) {
        return '<rect x="${o.x}" y="${o.y}" width="${o.width}" height="${o.height}" fill="#000" rx="$rx" ry="$rx"/>';
      }
      return '<rect x="${o.x + t / 2}" y="${o.y + t / 2}" width="${o.width - t}" height="${o.height - t}" fill="none" stroke="#000" stroke-width="$t" rx="$rx" ry="$rx"/>';

    case LineElement():
      final o = el.options;
      final t = o.thickness ?? 1;
      return '<line x1="${o.x1}" y1="${o.y1}" x2="${o.x2}" y2="${o.y2}" stroke="#000" stroke-width="$t"/>';

    case CircleElement():
      final o = el.options;
      final t = o.thickness ?? 1;
      final r = o.diameter / 2;
      if (t >= r) {
        return '<circle cx="${o.x + r}" cy="${o.y + r}" r="$r" fill="#000"/>';
      }
      return '<circle cx="${o.x + r}" cy="${o.y + r}" r="${(r - t / 2).round()}" fill="none" stroke="#000" stroke-width="$t"/>';

    case EllipseElement():
      final o = el.options;
      final t = o.thickness ?? 1;
      final rx = o.width / 2;
      final ry = o.height / 2;
      return '<ellipse cx="${o.x + rx}" cy="${o.y + ry}" rx="${rx.round()}" ry="${ry.round()}" fill="none" stroke="#000" stroke-width="$t"/>';

    case ReverseElement():
      final o = el.options;
      return '<rect x="${o.x}" y="${o.y}" width="${o.width}" height="${o.height}" fill="#000"/>';

    case EraseElement():
      final o = el.options;
      return '<rect x="${o.x}" y="${o.y}" width="${o.width}" height="${o.height}" fill="#fff"/>';

    case RawElement():
      return '';
  }
}

/// Render a resolved label as an SVG preview string.
String renderPreview(ResolvedLabel label, {String? languageName}) {
  final w = label.widthDots;
  final h = label.heightDots > 0 ? label.heightDots : 400;
  final padding = 10;
  final svgW = w + padding * 2;
  final svgH = h + padding * 2;

  final elements = StringBuffer();
  for (final el in label.elements) {
    elements.write(_renderElement(el));
  }

  final langSuffix = languageName != null ? ' — $languageName' : '';

  return [
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $svgW $svgH" width="$svgW" height="$svgH">',
    '<rect x="0" y="0" width="$svgW" height="$svgH" fill="#f5f5f4" rx="4"/>',
    '<rect x="$padding" y="$padding" width="$w" height="$h" fill="#fff" stroke="#e5e5e5" stroke-width="1" rx="2"/>',
    '<g transform="translate($padding,$padding)">',
    elements.toString(),
    '</g>',
    '<text x="${svgW / 2}" y="${svgH - 1}" text-anchor="middle" fill="#a1a1aa" font-size="8" font-family="monospace">${w}×$h dots (${label.dpi} DPI)$langSuffix</text>',
    '</svg>',
  ].join('\n');
}
