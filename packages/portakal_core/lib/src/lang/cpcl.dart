import 'dart:typed_data';

import '../builder.dart';
import '../encoding.dart';
import '../languages/cpcl.dart';
import '../parsers/cpcl.dart';
import '../preview.dart';
import '../types.dart';
import '../validate.dart' as v;

/// CPCL language module.
class CpclLang {
  /// Compile a [LabelBuilder] to CPCL binary commands as a canonical byte sequence ([Uint8List]).
  Uint8List compile(
    LabelBuilder builder, {
    CpclEncoding? encoding,
    UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
  }) =>
      compileToCPCLBytes(builder.resolve(), encoding: encoding, policy: policy);

  /// Compile a [LabelBuilder] to CPCL binary commands as [Uint8List].
  @Deprecated('Use compile() instead. compileBytes will be removed in 2.0.')
  Uint8List compileBytes(
    LabelBuilder builder, {
    CpclEncoding? encoding,
    UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
  }) => compile(builder, encoding: encoding, policy: policy);

  CPCLParseResult parse(String code) => parseCPCL(code);

  String preview(LabelBuilder builder) =>
      renderPreview(builder.resolve(), languageName: 'CPCL');

  v.ValidationResult validate(String code) => v.validate(code, 'cpcl');
}

final cpcl = CpclLang();
