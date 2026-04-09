import '../builder.dart';
import '../languages/tsc.dart';
import '../parsers/tsc.dart';
import '../preview.dart';
import '../validate.dart' as v;

/// TSC/TSPL2 language module.
class TscLang {
  String compile(LabelBuilder builder) => compileToTSC(builder.resolve());
  TSPLParseResult parse(String code) => parseTSPL(code);
  String preview(LabelBuilder builder) => renderPreview(builder.resolve(), languageName: 'TSC');
  v.ValidationResult validate(String code) => v.validate(code, 'tsc');
}

final tsc = TscLang();
