import '../builder.dart';
import '../languages/epl.dart';
import '../parsers/epl.dart';
import '../preview.dart';
import '../validate.dart' as v;

/// EPL2 language module.
class EplLang {
  String compile(LabelBuilder builder) => compileToEPL(builder.resolve());
  EPLParseResult parse(String code) => parseEPL(code);
  String preview(LabelBuilder builder) =>
      renderPreview(builder.resolve(), languageName: 'EPL');
  v.ValidationResult validate(String code) => v.validate(code, 'epl');
}

final epl = EplLang();
