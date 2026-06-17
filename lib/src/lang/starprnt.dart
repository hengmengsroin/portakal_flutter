import 'dart:typed_data';
import '../builder.dart';
import '../languages/starprnt.dart';
import '../parsers/starprnt.dart';
import '../preview.dart';
import '../validate.dart' as v;

class StarprntLang {
  Uint8List compile(LabelBuilder builder) =>
      compileToStarPRNT(builder.resolve());
  StarPRNTParseResult parse(Uint8List data) => parseStarPRNT(data);
  String preview(LabelBuilder builder) =>
      renderPreview(builder.resolve(), languageName: 'StarPRNT');
  v.ValidationResult validate(String code) => v.validate(code, 'starprnt');
}

final starprnt = StarprntLang();
