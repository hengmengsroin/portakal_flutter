import '../builder.dart';
import '../languages/dpl.dart';

class DplLang {
  String compile(LabelBuilder builder) {
    return compileToDPL(builder.resolve());
  }

  dynamic parse(String code) => throw UnimplementedError();
  String preview(LabelBuilder builder) => throw UnimplementedError();
  dynamic validate(String code) => throw UnimplementedError();
}

final dpl = DplLang();
