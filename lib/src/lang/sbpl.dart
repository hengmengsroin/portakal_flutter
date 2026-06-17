import '../builder.dart';
import '../languages/sbpl.dart';
import '../parsers/sbpl.dart';
import '../preview.dart';
import '../validate.dart' as v;

class SbplLang {
  String compile(LabelBuilder builder) => compileToSBPL(builder.resolve());
  SBPLParseResult parse(String code) => parseSBPL(code);
  String preview(LabelBuilder builder) =>
      renderPreview(builder.resolve(), languageName: 'SBPL');
  v.ValidationResult validate(String code) => v.validate(code, 'sbpl');
}

final sbpl = SbplLang();
