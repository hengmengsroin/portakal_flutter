import 'dart:typed_data';

import '../builder.dart';
import '../encoding.dart';
import '../languages/escpos.dart';
import '../parsers/escpos.dart';
import '../preview.dart';
import '../validate.dart' as v;

/// ESC/POS language module.
class EscposLang {
  /// Compile a [LabelBuilder] to ESC/POS binary commands as [Uint8List].
  Uint8List compile(LabelBuilder builder, {EscPosEncoding? encoding}) =>
      compileToESCPOS(builder.resolve(), encoding: encoding);

  /// Compile a [LabelBuilder] to ESC/POS binary commands as [Uint8List].
  ///
  /// Convenience alias for [compile] providing naming consistency across protocols.
  Uint8List compileBytes(LabelBuilder builder, {EscPosEncoding? encoding}) =>
      compileToESCPOSBytes(builder.resolve(), encoding: encoding);

  ESCPOSParseResult parse(Uint8List data) => parseESCPOS(data);

  String preview(LabelBuilder builder) =>
      renderPreview(builder.resolve(), languageName: 'ESC/POS');

  v.ValidationResult validate(String code) => v.validate(code, 'escpos');
}

final escpos = EscposLang();
