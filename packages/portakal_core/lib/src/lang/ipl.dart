import 'dart:typed_data';

import '../builder.dart';
import '../encoding.dart';
import '../languages/ipl.dart';
import '../parsers/ipl.dart';
import '../preview.dart';
import '../validate.dart' as v;

/// IPL language module.
class IplLang {
  /// Compile a [LabelBuilder] to IPL binary commands as [Uint8List].
  Uint8List compileBytes(LabelBuilder builder, {IplEncoding? encoding}) =>
      compileToIPLBytes(builder.resolve(), encoding: encoding);

  /// Compile a [LabelBuilder] to IPL commands as a [String].
  String compile(LabelBuilder builder, {IplEncoding? encoding}) =>
      compileToIPL(builder.resolve(), encoding: encoding);

  IPLParseResult parse(String code) => parseIPL(code);

  String preview(LabelBuilder builder) =>
      renderPreview(builder.resolve(), languageName: 'IPL');

  v.ValidationResult validate(String code) => v.validate(code, 'ipl');
}

final ipl = IplLang();
