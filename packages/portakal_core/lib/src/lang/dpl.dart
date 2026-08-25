import 'dart:typed_data';

import '../builder.dart';
import '../encoding.dart';
import '../languages/dpl.dart';
import '../parsers/dpl.dart';
import '../preview.dart';
import '../types.dart';
import '../validate.dart' as v;

/// DPL language module.
class DplLang {
  /// Compile a [LabelBuilder] to DPL binary commands as a canonical byte sequence ([Uint8List]).
  Uint8List compile(
    LabelBuilder builder, {
    DplEncoding? encoding,
    UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
  }) =>
      compileToDPLBytes(builder.resolve(), encoding: encoding, policy: policy);

  /// Compile a [LabelBuilder] to DPL binary commands as [Uint8List].
  @Deprecated('Use compile() instead. compileBytes will be removed in 2.0.')
  Uint8List compileBytes(
    LabelBuilder builder, {
    DplEncoding? encoding,
    UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
  }) => compile(builder, encoding: encoding, policy: policy);

  DPLParseResult parse(String code) => parseDPL(code);

  String preview(LabelBuilder builder) =>
      renderPreview(builder.resolve(), languageName: 'DPL');

  v.ValidationResult validate(String code) => v.validate(code, 'dpl');
}

final dpl = DplLang();
