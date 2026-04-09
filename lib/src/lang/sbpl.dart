import '../builder.dart';
import '../languages/sbpl.dart';

class SbplLang {
  String compile(LabelBuilder builder) {
    return compileToSBPL(builder.resolve());
  }

  dynamic parse(String code) => throw UnimplementedError();
  String preview(LabelBuilder builder) => throw UnimplementedError();
  dynamic validate(String code) => throw UnimplementedError();
}

final sbpl = SbplLang();
