import 'dart:typed_data';
import '../builder.dart';
import '../languages/escpos.dart';
import '../parsers/escpos.dart';
import '../preview.dart';
import '../validate.dart' as v;

/// ESC/POS language module.
class EscposLang {
  Uint8List compile(LabelBuilder builder) => compileToESCPOS(builder.resolve());
  ESCPOSParseResult parse(Uint8List data) => parseESCPOS(data);
  String preview(LabelBuilder builder) =>
      renderPreview(builder.resolve(), languageName: 'ESC/POS');
  v.ValidationResult validate(String code) => v.validate(code, 'escpos');
}

final escpos = EscposLang();
