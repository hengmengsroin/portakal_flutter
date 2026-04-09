import '../builder.dart';
import '../languages/cpcl.dart';

class CpclLang {
  String compile(LabelBuilder builder) {
    return compileToCPCL(builder.resolve());
  }

  dynamic parse(String code) => throw UnimplementedError();
  String preview(LabelBuilder builder) => throw UnimplementedError();
  dynamic validate(String code) => throw UnimplementedError();
}

final cpcl = CpclLang();
