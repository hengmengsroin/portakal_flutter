import 'dart:typed_data';

import '../builder.dart';
import '../encoding.dart';
import '../languages/starprnt.dart';
import '../parsers/starprnt.dart';
import '../preview.dart';
import '../validate.dart' as v;

/// Star PRNT language module.
class StarprntLang {
  /// Compile a [LabelBuilder] to Star PRNT binary commands as [Uint8List].
  Uint8List compile(LabelBuilder builder, {StarPrntEncoding? encoding}) =>
      compileToStarPRNT(builder.resolve(), encoding: encoding);

  /// Compile a [LabelBuilder] to Star PRNT binary commands as [Uint8List].
  ///
  /// Convenience alias for [compile] providing naming consistency across protocols.
  Uint8List compileBytes(LabelBuilder builder, {StarPrntEncoding? encoding}) =>
      compileToStarPRNTBytes(builder.resolve(), encoding: encoding);

  StarPRNTParseResult parse(Uint8List data) => parseStarPRNT(data);

  String preview(LabelBuilder builder) =>
      renderPreview(builder.resolve(), languageName: 'StarPRNT');

  v.ValidationResult validate(String code) => v.validate(code, 'starprnt');
}

final starprnt = StarprntLang();
