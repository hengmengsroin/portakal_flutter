import '../builder.dart';
import '../languages/cpcl.dart';
import '../parsers/cpcl.dart';
import '../preview.dart';
import '../validate.dart' as v;

class CpclLang {
  String compile(LabelBuilder builder) => compileToCPCL(builder.resolve());
  CPCLParseResult parse(String code) => parseCPCL(code);
  String preview(LabelBuilder builder) =>
      renderPreview(builder.resolve(), languageName: 'CPCL');
  v.ValidationResult validate(String code) => v.validate(code, 'cpcl');
}

final cpcl = CpclLang();
