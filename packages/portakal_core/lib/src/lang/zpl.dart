import 'dart:typed_data';

import '../builder.dart';
import '../encoding.dart';
import '../languages/zpl.dart';
import '../parsers/zpl.dart';
import '../preview.dart';
import '../types.dart';
import '../validate.dart' as v;

/// ZPL language module.
class ZplLang {
  /// Compile a [ResolvedLabel] to ZPL II binary commands as a canonical byte sequence ([Uint8List]).
  Uint8List compileResolved(
    ResolvedLabel job, {
    ZplEncoding? encoding,
    UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
  }) =>
      compileToZPLBytes(job, encoding: encoding, policy: policy);

  /// Compile a [LabelBuilder] to ZPL II binary commands as a canonical byte sequence ([Uint8List]).
  Uint8List compile(
    LabelBuilder builder, {
    ZplEncoding? encoding,
    UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
  }) =>
      compileResolved(builder.resolve(), encoding: encoding, policy: policy);

  /// Compile a [LabelBuilder] to ZPL II binary commands as [Uint8List].
  @Deprecated('Use compile() instead. compileBytes will be removed in 2.0.')
  Uint8List compileBytes(
    LabelBuilder builder, {
    ZplEncoding? encoding,
    UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
  }) =>
      compile(builder, encoding: encoding, policy: policy);

  ZPLParseResult parse(String code) => parseZPL(code);

  /// Generate an SVG preview string for a [LabelBuilder].
  String preview(LabelBuilder builder) =>
      renderPreview(builder.resolve(), languageName: 'ZPL');

  v.ValidationResult validate(String code) => v.validate(code, 'zpl');
}

final zpl = ZplLang();
