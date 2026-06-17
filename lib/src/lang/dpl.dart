import '../builder.dart';
import '../languages/dpl.dart';
import '../parsers/dpl.dart';
import '../preview.dart';
import '../validate.dart' as v;

class DplLang {
  String compile(LabelBuilder builder) => compileToDPL(builder.resolve());
  DPLParseResult parse(String code) => parseDPL(code);
  String preview(LabelBuilder builder) =>
      renderPreview(builder.resolve(), languageName: 'DPL');
  v.ValidationResult validate(String code) => v.validate(code, 'dpl');
}

final dpl = DplLang();
