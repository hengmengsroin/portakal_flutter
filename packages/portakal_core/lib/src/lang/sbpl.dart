import 'dart:typed_data';

import '../builder.dart';
import '../encoding.dart';
import '../languages/sbpl.dart';
import '../parsers/sbpl.dart';
import '../preview.dart';
import '../types.dart';
import '../validate.dart' as v;

/// SBPL language module.
class SbplLang {
  /// Compile a [LabelBuilder] to SBPL binary commands as a canonical byte sequence ([Uint8List]).
  Uint8List compile(
    LabelBuilder builder, {
    SbplEncoding? encoding,
    UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
  }) =>
      compileToSBPLBytes(builder.resolve(), encoding: encoding, policy: policy);

  /// Compile a [LabelBuilder] to SBPL binary commands as [Uint8List].
  @Deprecated('Use compile() instead. compileBytes will be removed in 2.0.')
  Uint8List compileBytes(
    LabelBuilder builder, {
    SbplEncoding? encoding,
    UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
  }) =>
      compile(builder, encoding: encoding, policy: policy);

  SBPLParseResult parse(String code) => parseSBPL(code);

  String preview(LabelBuilder builder) =>
      renderPreview(builder.resolve(), languageName: 'SBPL');

  v.ValidationResult validate(String code) => v.validate(code, 'sbpl');
}

final sbpl = SbplLang();
