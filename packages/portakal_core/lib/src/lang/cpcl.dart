import 'dart:typed_data';

import '../builder.dart';
import '../encoding.dart';
import '../languages/cpcl.dart';
import '../parsers/cpcl.dart';
import '../preview.dart';
import '../validate.dart' as v;

/// CPCL language module.
class CpclLang {
  /// Compile a [LabelBuilder] to CPCL binary commands as [Uint8List].
  Uint8List compileBytes(LabelBuilder builder, {CpclEncoding? encoding}) =>
      compileToCPCLBytes(builder.resolve(), encoding: encoding);

  /// Compile a [LabelBuilder] to CPCL commands as a [String].
  String compile(LabelBuilder builder, {CpclEncoding? encoding}) =>
      compileToCPCL(builder.resolve(), encoding: encoding);

  CPCLParseResult parse(String code) => parseCPCL(code);

  String preview(LabelBuilder builder) =>
      renderPreview(builder.resolve(), languageName: 'CPCL');

  v.ValidationResult validate(String code) => v.validate(code, 'cpcl');
}

final cpcl = CpclLang();
