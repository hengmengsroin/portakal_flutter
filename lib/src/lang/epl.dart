import 'dart:typed_data';

import '../builder.dart';
import '../encoding.dart';
import '../languages/epl.dart';
import '../parsers/epl.dart';
import '../preview.dart';
import '../validate.dart' as v;

/// EPL2 language module.
class EplLang {
  /// Compile a [LabelBuilder] to EPL2 binary commands as [Uint8List].
  Uint8List compileBytes(LabelBuilder builder, {EplEncoding? encoding}) =>
      compileToEPLBytes(builder.resolve(), encoding: encoding);

  /// Compile a [LabelBuilder] to EPL2 commands as a [String].
  String compile(LabelBuilder builder, {EplEncoding? encoding}) =>
      compileToEPL(builder.resolve(), encoding: encoding);

  EPLParseResult parse(String code) => parseEPL(code);

  String preview(LabelBuilder builder) =>
      renderPreview(builder.resolve(), languageName: 'EPL');

  v.ValidationResult validate(String code) => v.validate(code, 'epl');
}

final epl = EplLang();
