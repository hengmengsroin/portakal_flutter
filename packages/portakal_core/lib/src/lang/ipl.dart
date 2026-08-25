import 'dart:typed_data';

import '../builder.dart';
import '../encoding.dart';
import '../languages/ipl.dart';
import '../parsers/ipl.dart';
import '../preview.dart';
import '../types.dart';
import '../validate.dart' as v;

/// IPL language module.
class IplLang {
  /// Compile a [LabelBuilder] to IPL binary commands as a canonical byte sequence ([Uint8List]).
  Uint8List compile(
    LabelBuilder builder, {
    IplEncoding? encoding,
    UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
  }) =>
      compileToIPLBytes(builder.resolve(), encoding: encoding, policy: policy);

  /// Compile a [LabelBuilder] to IPL binary commands as [Uint8List].
  @Deprecated('Use compile() instead. compileBytes will be removed in 2.0.')
  Uint8List compileBytes(
    LabelBuilder builder, {
    IplEncoding? encoding,
    UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
  }) =>
      compile(builder, encoding: encoding, policy: policy);

  IPLParseResult parse(String code) => parseIPL(code);

  String preview(LabelBuilder builder) =>
      renderPreview(builder.resolve(), languageName: 'IPL');

  v.ValidationResult validate(String code) => v.validate(code, 'ipl');
}

final ipl = IplLang();
