import 'dart:typed_data';

import '../builder.dart';
import '../encoding.dart';
import '../languages/zpl.dart';
import '../parsers/zpl.dart';
import '../preview.dart';
import '../validate.dart' as v;

/// ZPL language module.
class ZplLang {
  /// Compile a [LabelBuilder] to ZPL II binary commands as [Uint8List].
  Uint8List compileBytes(LabelBuilder builder, {ZplEncoding? encoding}) =>
      compileToZPLBytes(builder.resolve(), encoding: encoding);

  /// Compile a [LabelBuilder] to ZPL II commands as a [String].
  String compile(LabelBuilder builder, {ZplEncoding? encoding}) =>
      compileToZPL(builder.resolve(), encoding: encoding);

  ZPLParseResult parse(String code) => parseZPL(code);

  String preview(LabelBuilder builder) =>
      renderPreview(builder.resolve(), languageName: 'ZPL');

  v.ValidationResult validate(String code) => v.validate(code, 'zpl');
}

final zpl = ZplLang();
