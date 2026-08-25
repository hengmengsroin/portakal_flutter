import 'dart:typed_data';

import '../builder.dart';
import '../encoding.dart';
import '../languages/sbpl.dart';
import '../parsers/sbpl.dart';
import '../preview.dart';
import '../validate.dart' as v;

/// SBPL language module.
class SbplLang {
  /// Compile a [LabelBuilder] to SBPL binary commands as [Uint8List].
  Uint8List compileBytes(LabelBuilder builder, {SbplEncoding? encoding}) =>
      compileToSBPLBytes(builder.resolve(), encoding: encoding);

  /// Compile a [LabelBuilder] to SBPL commands as a [String].
  String compile(LabelBuilder builder, {SbplEncoding? encoding}) =>
      compileToSBPL(builder.resolve(), encoding: encoding);

  SBPLParseResult parse(String code) => parseSBPL(code);

  String preview(LabelBuilder builder) =>
      renderPreview(builder.resolve(), languageName: 'SBPL');

  v.ValidationResult validate(String code) => v.validate(code, 'sbpl');
}

final sbpl = SbplLang();
