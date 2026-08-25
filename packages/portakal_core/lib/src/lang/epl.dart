import 'dart:typed_data';

import '../builder.dart';
import '../encoding.dart';
import '../languages/epl.dart';
import '../parsers/epl.dart';
import '../preview.dart';
import '../types.dart';
import '../validate.dart' as v;

/// EPL2 language module.
class EplLang {
  /// Compile a [LabelBuilder] to EPL2 binary commands as a canonical byte sequence ([Uint8List]).
  Uint8List compile(
    LabelBuilder builder, {
    EplEncoding? encoding,
    UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
  }) =>
      compileToEPLBytes(builder.resolve(), encoding: encoding, policy: policy);

  /// Compile a [LabelBuilder] to EPL2 binary commands as [Uint8List].
  @Deprecated('Use compile() instead. compileBytes will be removed in 2.0.')
  Uint8List compileBytes(
    LabelBuilder builder, {
    EplEncoding? encoding,
    UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
  }) => compile(builder, encoding: encoding, policy: policy);

  EPLParseResult parse(String code) => parseEPL(code);

  String preview(LabelBuilder builder) =>
      renderPreview(builder.resolve(), languageName: 'EPL');

  v.ValidationResult validate(String code) => v.validate(code, 'epl');
}

final epl = EplLang();
