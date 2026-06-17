import '../builder.dart';
import '../languages/ipl.dart';
import '../parsers/ipl.dart';
import '../preview.dart';
import '../validate.dart' as v;

class IplLang {
  String compile(LabelBuilder builder) => compileToIPL(builder.resolve());
  IPLParseResult parse(String code) => parseIPL(code);
  String preview(LabelBuilder builder) =>
      renderPreview(builder.resolve(), languageName: 'IPL');
  v.ValidationResult validate(String code) => v.validate(code, 'ipl');
}

final ipl = IplLang();
