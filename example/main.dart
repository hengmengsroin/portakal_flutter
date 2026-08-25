// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:portakal_flutter/portakal_flutter.dart';

void main() {
  final labelBuilder = label(
    LabelConfig(
      width: 40,
      height: 30,
      unit: Unit.mm,
      printer: 'zebra-zd420',
    ),
  )
      .text(
        'Hello Portakal',
        TextOptions(x: 16, y: 20, size: 2, bold: true),
      )
      .line(LineOptions(x1: 16, y1: 60, x2: 280, y2: 60, thickness: 2))
      .box(BoxOptions(x: 12, y: 12, width: 296, height: 200, thickness: 2));

  final tscBytes = tsc.compile(labelBuilder);
  final zplBytes = zpl.compile(labelBuilder);

  final tscText = utf8.decode(tscBytes);
  final zplText = utf8.decode(zplBytes);

  final converted = convert(tscText, 'tsc', 'zpl');
  final parsed = zpl.parse(zplText);
  final validation = zpl.validate(zplText);
  final svg = zpl.preview(labelBuilder);
  final convertedLength = switch (converted.output) {
    String value => value.length,
    List<int> value => value.length,
    _ => converted.output.toString().length,
  };

  print('=== Portakal Flutter Example ===');
  print('TSC byte output length: ${tscBytes.length}');
  print('ZPL byte output length: ${zplBytes.length}');
  print('Converted TSC -> ZPL length: $convertedLength');
  print('Parsed ZPL commands: ${parsed.commands.length}');
  print('Validation valid: ${validation.valid}');
  print('Validation issues: ${validation.issues.length}');
  print('SVG preview length: ${svg.length}');
  print(
    'Printer profile example (zebra-zd420): ${getProfile('zebra-zd420') != null}',
  );
  print(
    'Flutter widget preview example: flutter run -t example/flutter_preview.dart',
  );
}
