import 'dart:typed_data';

import '../builder.dart';
import '../encoding.dart';
import '../languages/escpos.dart';
import '../parsers/escpos.dart';
import '../preview.dart';
import '../types.dart';
import '../validate.dart' as v;

/// ESC/POS language module.
class EscposLang {
  /// Compile a [LabelBuilder] to ESC/POS binary commands as [Uint8List].
  Uint8List compile(
    LabelBuilder builder, {
    EscPosEncoding? encoding,
    UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
  }) =>
      compileToESCPOS(builder.resolve(), encoding: encoding, policy: policy);

  /// Compile a [LabelBuilder] to ESC/POS binary commands as [Uint8List].
  @Deprecated('Use compile() instead. compileBytes will be removed in 2.0.')
  Uint8List compileBytes(
    LabelBuilder builder, {
    EscPosEncoding? encoding,
    UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
  }) =>
      compile(builder, encoding: encoding, policy: policy);

  ESCPOSParseResult parse(Uint8List data) => parseESCPOS(data);

  String preview(LabelBuilder builder) =>
      renderPreview(builder.resolve(), languageName: 'ESC/POS');

  v.ValidationResult validate(String code) => v.validate(code, 'escpos');
}

final escpos = EscposLang();
