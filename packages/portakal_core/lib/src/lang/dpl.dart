import 'dart:typed_data';

import '../builder.dart';
import '../encoding.dart';
import '../languages/dpl.dart';
import '../parsers/dpl.dart';
import '../preview.dart';
import '../validate.dart' as v;

/// DPL language module.
class DplLang {
  /// Compile a [LabelBuilder] to DPL binary commands as [Uint8List].
  Uint8List compileBytes(LabelBuilder builder, {DplEncoding? encoding}) =>
      compileToDPLBytes(builder.resolve(), encoding: encoding);

  /// Compile a [LabelBuilder] to DPL commands as a [String].
  String compile(LabelBuilder builder, {DplEncoding? encoding}) =>
      compileToDPL(builder.resolve(), encoding: encoding);

  DPLParseResult parse(String code) => parseDPL(code);

  String preview(LabelBuilder builder) =>
      renderPreview(builder.resolve(), languageName: 'DPL');

  v.ValidationResult validate(String code) => v.validate(code, 'dpl');
}

final dpl = DplLang();
