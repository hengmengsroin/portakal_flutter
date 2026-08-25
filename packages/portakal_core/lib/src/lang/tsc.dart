import 'dart:typed_data';

import '../builder.dart';
import '../languages/tsc.dart';
import '../parsers/tsc.dart';
import '../preview.dart';
import '../types.dart';
import '../validate.dart' as v;

/// TSC/TSPL2 language module.
class TscLang {
  /// Compile a [LabelBuilder] to TSC/TSPL2 commands as a canonical byte sequence ([Uint8List]).
  Uint8List compile(
    LabelBuilder builder, {
    UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
  }) => compileToTSCBytes(builder.resolve(), policy: policy);

  /// Compile a [LabelBuilder] to TSC/TSPL2 commands as [Uint8List].
  @Deprecated('Use compile() instead. compileBytes will be removed in 2.0.')
  Uint8List compileBytes(
    LabelBuilder builder, {
    UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
  }) => compile(builder, policy: policy);

  TSPLParseResult parse(String code) => parseTSPL(code);

  String preview(LabelBuilder builder) =>
      renderPreview(builder.resolve(), languageName: 'TSC');

  v.ValidationResult validate(String code) => v.validate(code, 'tsc');
}

final tsc = TscLang();
