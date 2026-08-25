import 'preview_scene.dart';
import 'types.dart';

/// Escape XML special characters.
String _escapeXml(String s) {
  return s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}

String _fmt(num v) {
  if (v is int) return v.toString();
  if (v == v.truncateToDouble()) return v.toInt().toString();
  return ((v * 100).round() / 100).toString();
}

String _renderItem(PreviewItem item) {
  switch (item) {
    case PreviewTextItem():
      final ff = PreviewScene.fontFamily(item.font);
      final weight = item.bold ? 'bold' : 'normal';
      final decoration = item.underline ? ' text-decoration="underline"' : '';

      var transform = '';
      if (item.rotation != 0 && item.xScale != 1) {
        transform =
            ' transform="translate(${_fmt(item.x)} ${_fmt(item.y)}) rotate(${item.rotation}) scale(${item.xScale} 1) translate(${_fmt(-item.x)} ${_fmt(-item.y)})"';
      } else if (item.rotation != 0) {
        transform =
            ' transform="rotate(${item.rotation} ${_fmt(item.x)} ${_fmt(item.y)})"';
      } else if (item.xScale != 1) {
        transform =
            ' transform="translate(${_fmt(item.x)} ${_fmt(item.y)}) scale(${item.xScale} 1) translate(${_fmt(-item.x)} ${_fmt(-item.y)})"';
      }

      final anchor =
          item.svgAnchor != 'start' ? ' text-anchor="${item.svgAnchor}"' : '';
      final fill = item.isReverse ? '#fff' : '#000';

      final lines = item.text.split('\n');
      if (lines.length <= 1) {
        return '<text x="${_fmt(item.textAnchorX)}" y="${_fmt(item.svgY)}" fill="$fill" font-size="${item.fontSize}" font-weight="$weight" font-family="$ff"$anchor$decoration$transform>${_escapeXml(item.text)}</text>';
      }

      final tspans = StringBuffer();
      final lineHeight = item.fontSize * 1.2;
      for (var i = 0; i < lines.length; i++) {
        final dy = i == 0 ? '0' : _fmt(lineHeight);
        tspans.write(
          '<tspan x="${_fmt(item.textAnchorX)}" dy="$dy">${_escapeXml(lines[i])}</tspan>',
        );
      }

      return '<text x="${_fmt(item.textAnchorX)}" y="${_fmt(item.svgY)}" fill="$fill" font-size="${item.fontSize}" font-weight="$weight" font-family="$ff"$anchor$decoration$transform>$tspans</text>';

    case PreviewRectItem():
      final colorHex = item.color == PreviewColor.white ? '#fff' : '#000';
      final rxAttr = item.radius > 0
          ? ' rx="${_fmt(item.radius)}" ry="${_fmt(item.radius)}"'
          : '';
      if (item.isFilled) {
        return '<rect x="${_fmt(item.x)}" y="${_fmt(item.y)}" width="${_fmt(item.width)}" height="${_fmt(item.height)}" fill="$colorHex"$rxAttr/>';
      }
      return '<rect x="${_fmt(item.x)}" y="${_fmt(item.y)}" width="${_fmt(item.width)}" height="${_fmt(item.height)}" fill="none" stroke="$colorHex" stroke-width="${_fmt(item.thickness)}"$rxAttr/>';

    case PreviewLineItem():
      final colorHex = item.color == PreviewColor.white ? '#fff' : '#000';
      return '<line x1="${_fmt(item.x1)}" y1="${_fmt(item.y1)}" x2="${_fmt(item.x2)}" y2="${_fmt(item.y2)}" stroke="$colorHex" stroke-width="${_fmt(item.thickness)}"/>';

    case PreviewCircleItem():
      final colorHex = item.color == PreviewColor.white ? '#fff' : '#000';
      if (item.isFilled) {
        return '<circle cx="${_fmt(item.cx)}" cy="${_fmt(item.cy)}" r="${_fmt(item.radius)}" fill="$colorHex"/>';
      }
      return '<circle cx="${_fmt(item.cx)}" cy="${_fmt(item.cy)}" r="${item.radius.round()}" fill="none" stroke="$colorHex" stroke-width="${_fmt(item.thickness)}"/>';

    case PreviewOvalItem():
      final colorHex = item.color == PreviewColor.white ? '#fff' : '#000';
      return '<ellipse cx="${_fmt(item.cx)}" cy="${_fmt(item.cy)}" rx="${item.rx.round()}" ry="${item.ry.round()}" fill="none" stroke="$colorHex" stroke-width="${_fmt(item.thickness)}"/>';

    case PreviewBarcodeItem():
      final transform = item.rotation != 0
          ? ' transform="rotate(${item.rotation} ${_fmt(item.x)} ${_fmt(item.y)})"'
          : '';
      final buf = StringBuffer();
      buf.write('<g$transform>');
      for (final bar in item.bars) {
        buf.write(
          '<rect x="${_fmt(item.x + bar.targetX)}" y="${_fmt(item.y + bar.targetY)}" width="${_fmt(bar.targetWidth)}" height="${_fmt(bar.targetHeight)}" fill="#000"/>',
        );
      }
      if (item.readable) {
        final textY = item.y + item.height - 2.0;
        final textX = item.x + item.width / 2.0;
        buf.write(
          '<text x="${_fmt(textX)}" y="${_fmt(textY)}" fill="#000" font-size="10" font-family="monospace" text-anchor="middle">${_escapeXml(item.payload)}</text>',
        );
      }
      buf.write('</g>');
      return buf.toString();

    case PreviewQrItem():
      final transform = item.rotation != 0
          ? ' transform="rotate(${item.rotation} ${_fmt(item.x)} ${_fmt(item.y)})"'
          : '';
      final buf = StringBuffer();
      buf.write('<g$transform>');
      buf.write(
        '<rect x="${_fmt(item.x)}" y="${_fmt(item.y)}" width="${_fmt(item.width)}" height="${_fmt(item.height)}" fill="#fff"/>',
      );
      for (final m in item.modules) {
        buf.write(
          '<rect x="${_fmt(item.x + m.targetX)}" y="${_fmt(item.y + m.targetY)}" width="${_fmt(m.targetWidth)}" height="${_fmt(m.targetHeight)}" fill="#000"/>',
        );
      }
      buf.write('</g>');
      return buf.toString();

    case PreviewPlaceholderItem():
      final transform = item.rotation != 0
          ? ' transform="rotate(${item.rotation} ${_fmt(item.x)} ${_fmt(item.y)})"'
          : '';
      final textY = item.kind == PreviewPlaceholderKind.barcode
          ? (item.y + item.height / 2.0 + 3.0)
          : (item.y + 12.0);
      final fontSize = item.kind == PreviewPlaceholderKind.barcode ? 10 : 8;
      final labelEscaped = _escapeXml(item.label);

      final buf = StringBuffer();
      buf.write('<g$transform>');
      buf.write(
        '<rect x="${_fmt(item.x)}" y="${_fmt(item.y)}" width="${_fmt(item.width)}" height="${_fmt(item.height)}" fill="#e4e4e7" stroke="#71717a" stroke-width="1" stroke-dasharray="3,3"/>',
      );
      buf.write(
        '<text x="${_fmt(item.x + 4)}" y="${_fmt(textY)}" fill="#18181b" font-size="$fontSize" font-family="monospace">$labelEscaped</text>',
      );
      buf.write('</g>');
      return buf.toString();

    case PreviewBitmapItem():
      final buf = StringBuffer();
      for (final span in item.spans) {
        buf.write(
          '<rect x="${_fmt(span.targetX)}" y="${_fmt(span.targetY)}" width="${_fmt(span.targetWidth)}" height="${_fmt(span.targetHeight)}" fill="#000"/>',
        );
      }
      return buf.toString();
  }
}

/// Render a [PreviewScene] as an SVG preview string.
String renderPreviewScene(PreviewScene scene) {
  final w = scene.widthDots;
  final h = scene.heightDots;
  final padding = 10;
  final svgW = w + padding * 2;
  final svgH = h + padding * 2;

  final elements = StringBuffer();
  for (final item in scene.items) {
    elements.write(_renderItem(item));
  }

  final langSuffix =
      scene.languageName != null ? ' — ${scene.languageName}' : '';

  return [
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $svgW $svgH" width="$svgW" height="$svgH">',
    '<defs>',
    '<clipPath id="portakal-label-clip">',
    '<rect x="0" y="0" width="$w" height="$h"/>',
    '</clipPath>',
    '</defs>',
    '<rect x="0" y="0" width="$svgW" height="$svgH" fill="#f5f5f4" rx="4"/>',
    '<rect x="$padding" y="$padding" width="$w" height="$h" fill="#fff" stroke="#e5e5e5" stroke-width="1" rx="2"/>',
    '<g transform="translate($padding,$padding)" clip-path="url(#portakal-label-clip)">',
    elements.toString(),
    '</g>',
    '<text x="${_fmt(svgW / 2)}" y="${svgH - 1}" text-anchor="middle" fill="#a1a1aa" font-size="8" font-family="monospace">$w×$h dots (${scene.dpi} DPI)$langSuffix</text>',
    '</svg>',
  ].join('\n');
}

/// Render a resolved label as an SVG preview string.
String renderPreview(ResolvedLabel label, {String? languageName}) {
  final scene = PreviewScene.fromResolved(label, languageName: languageName);
  return renderPreviewScene(scene);
}
