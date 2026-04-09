import '../builder.dart';
import '../languages/zpl.dart';
import '../parsers/zpl.dart';
import '../preview.dart';
import '../validate.dart' as v;

class ZplLang {
  String compile(LabelBuilder builder) => compileToZPL(builder.resolve());
  ZPLParseResult parse(String code) => parseZPL(code);
  String preview(LabelBuilder builder) => renderPreview(builder.resolve(), languageName: 'ZPL');
  v.ValidationResult validate(String code) => v.validate(code, 'zpl');
}

final zpl = ZplLang();
