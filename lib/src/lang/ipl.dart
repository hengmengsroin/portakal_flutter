import '../builder.dart';
import '../languages/ipl.dart';

class IplLang {
  String compile(LabelBuilder builder) {
    return compileToIPL(builder.resolve());
  }

  dynamic parse(String code) => throw UnimplementedError();
  String preview(LabelBuilder builder) => throw UnimplementedError();
  dynamic validate(String code) => throw UnimplementedError();
}

final ipl = IplLang();
